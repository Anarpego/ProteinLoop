"""Validate final lablab submission readiness."""

from __future__ import annotations

import json
import ipaddress
import re
import subprocess
import sys
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
LABLAB = SUBMISSION / "lablab-submission.md"

sys.path.insert(0, str(ROOT))

from scripts.export_lablab_form import export_form  # noqa: E402
from scripts.validate_submission_artifacts import BUNDLE, MANIFEST, bundle_ok  # noqa: E402

REQUIRED_ARTIFACTS = [
    ROOT / "README.md",
    ROOT / "LICENSE",
    ROOT / "docker-compose.yml",
    ROOT / ".github" / "workflows" / "ci.yml",
    SUBMISSION / "lablab-submission.md",
    SUBMISSION / "video-script.md",
    SUBMISSION / "slides.md",
    SUBMISSION / "cover.svg",
    SUBMISSION / "cover.png",
    SUBMISSION / "proteinloop-hackathon-deck.pptx",
    SUBMISSION / "proteinloop-demo-video.avi",
    SUBMISSION / "demo-evidence.json",
    SUBMISSION / "demo-evidence.md",
    SUBMISSION / "demo-rehearsal.json",
    SUBMISSION / "demo-rehearsal.md",
    SUBMISSION / "mesh-evidence.json",
    SUBMISSION / "mesh-evidence.md",
    SUBMISSION / "nrf9151-field-plan.json",
    SUBMISSION / "nrf9151-field-plan.md",
    SUBMISSION / "nrf9151-telemetry-bridge.json",
    SUBMISSION / "nrf9151-telemetry-bridge.md",
    SUBMISSION / "gemma-evidence.json",
    SUBMISSION / "proteinloop-lablab-upload.zip",
    SUBMISSION / "bundle-manifest.json",
    SUBMISSION / "lablab-form.json",
    SUBMISSION / "final-readiness-report.md",
]


@dataclass(frozen=True)
class Check:
    name: str
    ok: bool
    detail: str = ""


def main() -> int:
    checks = run_checks(ROOT, LABLAB)

    for check in checks:
        mark = "ok" if check.ok else "FAIL"
        suffix = f" - {check.detail}" if check.detail else ""
        print(f"[{mark}] {check.name}{suffix}")

    failed = [check for check in checks if not check.ok]
    if failed:
        print(f"{len(failed)} submission readiness check(s) failed", file=sys.stderr)
        return 1

    print("submission readiness OK")
    return 0


def run_checks(root: Path, lablab_path: Path) -> list[Check]:
    checks: list[Check] = []

    missing = [path.relative_to(root).as_posix() for path in REQUIRED_ARTIFACTS if not path.exists()]
    checks.append(Check("required local artifacts", not missing, ", ".join(missing)))
    checks.append(lablab_form_check(lablab_path, SUBMISSION / "lablab-form.json"))
    checks.append(submission_bundle_check(BUNDLE, MANIFEST))
    checks.append(gemma_evidence_check(SUBMISSION / "gemma-evidence.json"))

    lablab_text = lablab_path.read_text(encoding="utf-8") if lablab_path.exists() else ""
    repo_url = extract_labeled_url(lablab_text, "Public GitHub Repository")
    app_url = extract_application_url(lablab_text)

    checks.append(url_check("public GitHub repository URL", repo_url, required_host="github.com"))
    checks.append(url_check("application URL", app_url, require_public=True))
    checks.extend(public_url_checks(repo_url, app_url))

    checks.extend(git_checks(root, repo_url))

    return checks


def extract_labeled_url(text: str, label: str) -> str | None:
    pattern = re.compile(rf"^{re.escape(label)}\s*:\s*(?P<value>\S+)\s*$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        return None
    value = match.group("value").strip()
    if value.upper() == "TODO":
        return None
    return value


def lablab_form_check(lablab_path: Path, form_path: Path) -> Check:
    if not lablab_path.exists():
        return Check("lablab form matches draft", False, f"missing {display_path(lablab_path)}")
    if not form_path.exists():
        return Check("lablab form matches draft", False, f"missing {display_path(form_path)}")

    try:
        expected = export_form(lablab_path.read_text(encoding="utf-8"))
        actual = json.loads(form_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return Check("lablab form matches draft", False, f"invalid JSON: {exc}")

    if actual != expected:
        return Check("lablab form matches draft", False, "stale; run make submission-form")
    return Check("lablab form matches draft", True, display_path(form_path))


def submission_bundle_check(bundle_path: Path, manifest_path: Path) -> Check:
    if not bundle_path.exists():
        return Check("submission bundle contents", False, f"missing {display_path(bundle_path)}")
    if not manifest_path.exists():
        return Check("submission bundle contents", False, f"missing {display_path(manifest_path)}")

    try:
        ok = bundle_ok(bundle_path, manifest_path)
    except Exception as exc:  # noqa: BLE001 - final readiness should report malformed bundle state plainly.
        return Check("submission bundle contents", False, str(exc))

    if not ok:
        return Check("submission bundle contents", False, "stale or incomplete; run make submission-bundle")
    return Check("submission bundle contents", True, display_path(bundle_path))


def display_path(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def extract_application_url(text: str) -> str | None:
    labeled = extract_labeled_url(text, "Application URL")
    if labeled:
        return labeled

    section = extract_markdown_section_value(text, "Application URL")
    if not section or section.upper() == "TODO":
        return None
    return section


def extract_markdown_section_value(text: str, heading: str) -> str | None:
    pattern = re.compile(
        rf"^##\s+{re.escape(heading)}\s*$\n(?P<body>.*?)(?=^##\s+|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(text)
    if not match:
        return None

    for line in match.group("body").splitlines():
        value = line.strip()
        if value:
            return value
    return None


def url_check(
    name: str,
    url: str | None,
    required_host: str | None = None,
    require_public: bool = False,
) -> Check:
    if not url:
        return Check(name, False, "missing or TODO")

    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return Check(name, False, f"expected http(s) URL, got {url}")

    if required_host and parsed.netloc.lower() != required_host:
        return Check(name, False, f"expected host {required_host}, got {parsed.netloc}")

    if require_public and not is_public_http_url(url):
        return Check(name, False, f"expected public http(s) URL, got {url}")

    return Check(name, True, url)


def is_public_http_url(url: str) -> bool:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        return False

    host = parsed.hostname.strip("[]").lower()
    if host in {"localhost"} or host.endswith(".localhost"):
        return False

    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        return True

    return not (
        address.is_loopback
        or address.is_private
        or address.is_link_local
        or address.is_multicast
        or address.is_reserved
        or address.is_unspecified
    )


def gemma_evidence_check(path: Path) -> Check:
    if not path.exists():
        return Check("Gemma endpoint evidence", False, "missing submission/gemma-evidence.json")

    try:
        evidence = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return Check("Gemma endpoint evidence", False, f"invalid JSON: {exc}")

    model = str(evidence.get("model", ""))
    if "gemma-4" not in model.lower():
        return Check("Gemma endpoint evidence", False, f"expected Gemma 4 model, got {model!r}")

    models = evidence.get("models")
    if not isinstance(models, list) or not all(isinstance(item, str) for item in models):
        return Check("Gemma endpoint evidence", False, "missing advertised models list")
    if not model_is_advertised(model, models):
        return Check("Gemma endpoint evidence", False, f"model {model!r} not advertised by /v1/models")

    endpoint = str(evidence.get("endpoint", ""))
    parsed = urllib.parse.urlparse(endpoint)
    if parsed.hostname in {"127.0.0.1", "localhost", "::1"}:
        return Check("Gemma endpoint evidence", False, "endpoint must not be localhost for final submission")

    action = evidence.get("action")
    if not isinstance(action, dict):
        return Check("Gemma endpoint evidence", False, "missing action object")

    required_action_keys = {
        "feed_kg",
        "aeration_hours",
        "water_exchange_fraction",
        "duckweed_harvest_kg",
    }
    missing_action = sorted(required_action_keys - set(action))
    if missing_action:
        return Check("Gemma endpoint evidence", False, f"action missing: {', '.join(missing_action)}")

    checks = evidence.get("checks")
    if not isinstance(checks, list) or not checks:
        return Check("Gemma endpoint evidence", False, "missing endpoint checks")

    failed = [str(check.get("name", "unnamed")) for check in checks if not check.get("ok")]
    if failed:
        return Check("Gemma endpoint evidence", False, f"failed checks: {', '.join(failed)}")

    return Check("Gemma endpoint evidence", True, model)


def model_is_advertised(model: str, model_ids: list[str]) -> bool:
    normalized = model.strip().lower().strip("/")
    if not normalized:
        return False

    for model_id in model_ids:
        candidate = model_id.strip().lower().strip("/")
        if candidate == normalized or candidate.endswith(f"/{normalized}"):
            return True

    return False


def public_url_checks(repo_url: str | None, app_url: str | None) -> list[Check]:
    checks: list[Check] = []

    if repo_url and url_check("repo", repo_url, required_host="github.com").ok:
        checks.append(reachable_check("public GitHub repository reachable", repo_url))

    if app_url and url_check("app", app_url).ok:
        app_base = app_url.rstrip("/")
        checks.append(
            reachable_check(
                "application dashboard reachable",
                app_base,
                required_text="Operator dashboard",
            )
        )
        checks.append(
            reachable_check(
                "application producer route reachable",
                f"{app_base}/producer",
                required_text="Productor",
            )
        )

    return checks


def reachable_check(
    name: str,
    url: str,
    required_text: str | None = None,
    request_fun=None,
) -> Check:
    request_fun = request_fun or http_get_text

    try:
        text = request_fun(url)
    except Exception as exc:  # noqa: BLE001 - final readiness should report any URL failure plainly.
        return Check(name, False, f"{url}: {exc}")

    if required_text and required_text not in text:
        return Check(name, False, f"{url}: missing marker {required_text!r}")

    return Check(name, True, url)


def http_get_text(url: str, timeout: float = 10.0) -> str:
    request = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read().decode("utf-8", errors="replace")


def git_checks(root: Path, repo_url: str | None) -> list[Check]:
    git_dir = root / ".git"
    checks = [Check("local git repository", git_dir.exists() and git_dir.is_dir())]

    commit = git_output(root, ["rev-parse", "--verify", "HEAD"])
    checks.append(Check("local git commit", commit.ok, commit.detail))

    origin = git_output(root, ["config", "--get", "remote.origin.url"])
    checks.append(Check("origin remote configured", origin.ok, origin.detail))

    if repo_url and origin.ok:
        checks.append(
            Check(
                "origin matches lablab repository URL",
                normalize_git_remote(origin.detail) == normalize_git_remote(repo_url),
                f"origin={origin.detail} lablab={repo_url}",
            )
        )
    else:
        checks.append(Check("origin matches lablab repository URL", False, "missing repo URL or origin"))

    return checks


def git_output(root: Path, args: list[str]) -> Check:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return Check("git command", False, str(exc))

    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or f"git {' '.join(args)} failed"
        return Check("git command", False, detail)

    return Check("git command", True, result.stdout.strip())


def normalize_git_remote(url: str) -> str:
    cleaned = url.strip()
    if cleaned.endswith(".git"):
        cleaned = cleaned[:-4]

    ssh_match = re.match(r"^git@github\.com:(?P<owner>[^/]+)/(?P<repo>.+)$", cleaned)
    if ssh_match:
        return f"github.com/{ssh_match.group('owner')}/{ssh_match.group('repo')}".lower()

    parsed = urllib.parse.urlparse(cleaned)
    if parsed.netloc:
        return f"{parsed.netloc}{parsed.path}".strip("/").lower()

    return cleaned.lower()


if __name__ == "__main__":
    raise SystemExit(main())
