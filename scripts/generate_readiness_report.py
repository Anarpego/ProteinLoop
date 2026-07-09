"""Generate a final submission readiness report."""

from __future__ import annotations

import datetime as dt
import json
import subprocess
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
OUTPUT = SUBMISSION / "final-readiness-report.md"
DOCKER_SMOKE_EVIDENCE = SUBMISSION / "docker-smoke-evidence.json"
GENERATED_ARTIFACT_PATHS = [
    "submission/bundle-manifest.json",
    "submission/docker-smoke-evidence.json",
    "submission/final-readiness-report.md",
    "submission/proteinloop-lablab-upload.zip",
]

EVIDENCE_COMMANDS = [
    ("Unit tests", ["make", "test"]),
    ("Submission artifacts", ["make", "submission-check"]),
    ("Docker smoke", ["make", "docker-smoke"]),
    ("CI workflow contract", ["make", "ci-check"]),
    ("Public deploy profile", ["make", "public-deploy-check"]),
    ("Credit access", ["make", "credit-check"]),
    ("Public demo environment", ["make", "public-env-check"]),
    ("Gemma endpoint evidence", ["make", "gemma-check"]),
    ("Final submission readiness", ["make", "submission-ready-check"]),
    ("GitHub CLI authentication", ["gh", "auth", "status"]),
]


@dataclass(frozen=True)
class CommandEvidence:
    name: str
    command: list[str]
    returncode: int
    stdout: str
    stderr: str

    @property
    def ok(self) -> bool:
        return self.returncode == 0


def main() -> int:
    generated_at = dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat()
    commit = git_text(["rev-parse", "--short", "HEAD"]) or "unknown"
    working_tree = source_working_tree_status() or "clean"

    evidence = collect_evidence()

    OUTPUT.write_text(
        render_report(
            generated_at=generated_at,
            commit=commit,
            working_tree=working_tree,
            evidence=evidence,
        ),
        encoding="utf-8",
    )
    print(f"wrote {OUTPUT.relative_to(ROOT)}")
    return 0


def collect_evidence() -> list[CommandEvidence]:
    evidence: list[CommandEvidence] = []
    for name, command in EVIDENCE_COMMANDS:
        if name == "Docker smoke":
            evidence.append(docker_smoke_evidence(DOCKER_SMOKE_EVIDENCE))
        else:
            evidence.append(run_command(name, command))
    return evidence


def run_command(name: str, command: list[str]) -> CommandEvidence:
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
            timeout=120,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return CommandEvidence(name, command, 124, "", str(exc))

    return CommandEvidence(
        name=name,
        command=command,
        returncode=result.returncode,
        stdout=result.stdout.strip(),
        stderr=result.stderr.strip(),
    )


def docker_smoke_evidence(path: Path) -> CommandEvidence:
    command = ["make", "docker-smoke"]
    path_label = display_path(path)
    if not path.exists():
        return CommandEvidence(
            "Docker smoke",
            command,
            1,
            "",
            f"missing {path_label}; run make docker-smoke",
        )

    try:
        evidence = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return CommandEvidence("Docker smoke", command, 1, "", f"invalid {path_label}: {exc}")

    checks = evidence.get("checks")
    if not isinstance(checks, list):
        return CommandEvidence("Docker smoke", command, 1, "", f"{path_label} missing checks")

    lines = [
        f"evidence: {path_label}",
        f"checked_at: {evidence.get('checked_at', 'unknown')}",
    ]
    for check in checks:
        if not isinstance(check, dict):
            continue
        mark = "ok" if check.get("ok") else "FAIL"
        detail = f" - {check.get('detail')}" if check.get("detail") else ""
        lines.append(f"[{mark}] {check.get('name', 'unnamed')}{detail}")

    ok = evidence.get("ok") is True and checks and all(isinstance(check, dict) and check.get("ok") for check in checks)
    if ok:
        lines.append("docker smoke OK")

    return CommandEvidence("Docker smoke", command, 0 if ok else 1, "\n".join(lines), "")


def display_path(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def git_text(args: list[str]) -> str:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def source_working_tree_status() -> str:
    return git_text(
        [
            "status",
            "--short",
            "--",
            ".",
            *[f":(exclude){path}" for path in GENERATED_ARTIFACT_PATHS],
        ]
    )


def status_label(evidence: CommandEvidence) -> str:
    return "PASS" if evidence.ok else "FAIL"


def combined_output(evidence: CommandEvidence) -> str:
    return "\n".join(part for part in [evidence.stdout, evidence.stderr] if part).strip()


def extract_blockers(evidence: list[CommandEvidence]) -> list[str]:
    blockers: list[str] = []

    for item in evidence:
        if item.ok:
            continue

        output = combined_output(item)
        failure_lines = [
            line.strip()
            for line in output.splitlines()
            if line.strip().startswith("[FAIL]") or "token in default is invalid" in line
        ]

        if failure_lines:
            blockers.extend(f"{item.name}: {line}" for line in failure_lines)
        else:
            blockers.append(f"{item.name}: exited {item.returncode}")

    return blockers


def render_report(
    *,
    generated_at: str,
    commit: str,
    working_tree: str,
    evidence: list[CommandEvidence],
) -> str:
    blockers = extract_blockers(evidence)
    lines = [
        "# ProteinLoop Final Readiness Report",
        "",
        f"Generated: {generated_at}",
        f"Commit: `{commit}`",
        f"Working tree (source): `{working_tree}`",
        "",
        "## Command Evidence",
        "",
        "| Gate | Command | Exit | Status |",
        "| --- | --- | ---: | --- |",
    ]

    for item in evidence:
        command = " ".join(item.command)
        lines.append(f"| {item.name} | `{command}` | {item.returncode} | {status_label(item)} |")

    lines.extend(
        [
            "",
            "## Remaining Blockers",
            "",
        ]
    )
    if blockers:
        lines.extend(f"- {blocker}" for blocker in blockers)
    else:
        lines.append("- None. Final readiness gates are passing.")

    lines.extend(
        [
            "",
            "## Next Commands",
            "",
            "```sh",
            "gh auth login -h github.com",
            "make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop",
            "PHX_HOST=your-demo-host SECRET_KEY_BASE=$(cd app && mix phx.gen.secret) make public-env-check",
            "FIREWORKS_API_KEY=your-fireworks-key AMD_CLOUD_STATUS=active make credit-check",
            "make set-demo-url DEMO_URL=https://your-public-demo-url",
            "make gemma-check GEMMA_ENDPOINT=https://your-gemma-endpoint GEMMA_MODEL=google/gemma-4-E4B-it",
            "make submission-ready-check",
            "```",
            "",
            "## Output Snippets",
            "",
        ]
    )

    for item in evidence:
        output = combined_output(item)
        if not output:
            continue
        lines.extend(
            [
                f"### {item.name}",
                "",
                "```text",
                truncate_output(output),
                "```",
                "",
            ]
        )

    return "\n".join(lines).rstrip() + "\n"


def truncate_output(text: str, limit: int = 2400) -> str:
    if len(text) <= limit:
        return text
    return text[: limit - 80].rstrip() + "\n...[truncated]"


if __name__ == "__main__":
    raise SystemExit(main())
