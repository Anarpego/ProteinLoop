"""Validate hackathon credit access before Gemma endpoint deployment."""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_FIREWORKS_BASE_URL = "https://api.fireworks.ai/inference/v1"
DEFAULT_REPORT_PATH = ROOT / "submission" / "credit-access-report.json"
TIMEOUT_SECONDS = 15.0

RequestFun = Callable[[str, str, float], dict[str, Any]]


@dataclass(frozen=True)
class Check:
    name: str
    ok: bool
    detail: str = ""


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    api_key = args.fireworks_api_key or os.environ.get("FIREWORKS_API_KEY", "")
    base_url = args.fireworks_base_url or os.environ.get("FIREWORKS_BASE_URL") or DEFAULT_FIREWORKS_BASE_URL
    amd_status = args.amd_cloud_status or os.environ.get("AMD_CLOUD_STATUS", "")

    try:
        fireworks_checks = validate_fireworks_access(api_key, base_url, get_models_json, args.timeout)
    except ValueError as exc:
        fireworks_checks = [Check("Fireworks base URL", False, str(exc))]

    amd_check = validate_amd_cloud_status(amd_status)
    report = build_report(fireworks_checks, amd_check)

    for check in report["checks"]:
        mark = "ok" if check["ok"] else "FAIL"
        suffix = f" - {check['detail']}" if check["detail"] else ""
        print(f"[{mark}] {check['name']}{suffix}")

    if args.write_report:
        write_report(Path(args.report_file), report)
        print(f"wrote {Path(args.report_file).relative_to(ROOT)}")

    if not report["ok"]:
        print("credit access check failed", file=sys.stderr)
        return 1

    print("credit access OK")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fireworks-api-key", help="Defaults to FIREWORKS_API_KEY.")
    parser.add_argument("--fireworks-base-url", help=f"Defaults to {DEFAULT_FIREWORKS_BASE_URL}.")
    parser.add_argument("--amd-cloud-status", help="Set to active after AMD Cloud console shows credits/quota.")
    parser.add_argument("--timeout", type=float, default=TIMEOUT_SECONDS)
    parser.add_argument("--write-report", action="store_true", help="Write submission/credit-access-report.json.")
    parser.add_argument("--report-file", default=str(DEFAULT_REPORT_PATH))
    return parser.parse_args(argv)


def validate_fireworks_access(
    api_key: str,
    base_url: str,
    request_fun: RequestFun,
    timeout: float = TIMEOUT_SECONDS,
) -> list[Check]:
    if not api_key:
        return [Check("Fireworks API key", False, "set FIREWORKS_API_KEY from the Fireworks dashboard")]

    normalized = normalize_base_url(base_url)
    models_url = join_url(normalized, "/models")

    try:
        payload = request_fun(models_url, api_key, timeout)
    except Exception as exc:  # noqa: BLE001 - credit preflight should report provider errors plainly.
        return [
            Check("Fireworks API key", True, "configured"),
            Check("Fireworks models endpoint", False, f"{models_url}: {exc}"),
        ]

    model_ids = extract_model_ids(payload)
    return [
        Check("Fireworks API key", True, "configured"),
        Check("Fireworks models endpoint", bool(model_ids), f"{len(model_ids)} model(s) visible"),
    ]


def validate_amd_cloud_status(status: str) -> Check:
    normalized = status.strip().lower()
    if normalized == "active":
        return Check("AMD Cloud credits", True, "AMD_CLOUD_STATUS=active")
    if normalized:
        return Check("AMD Cloud credits", False, f"status {normalized!r}; set AMD_CLOUD_STATUS=active after console verification")
    return Check(
        "AMD Cloud credits",
        False,
        "set AMD_CLOUD_STATUS=active after AMD Cloud console shows credits and GPU quota",
    )


def build_report(fireworks_checks: list[Check], amd_check: Check) -> dict[str, Any]:
    checks = [*fireworks_checks, amd_check]
    return {
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "ok": all(check.ok for check in checks),
        "checks": [asdict(check) for check in checks],
        "next_steps": next_steps(checks),
    }


def next_steps(checks: list[Check]) -> list[str]:
    if all(check.ok for check in checks):
        return [
            "Deploy or configure an OpenAI-compatible Gemma endpoint.",
            "Run GEMMA_ENDPOINT=https://... GEMMA_MODEL=google/gemma-4-E4B-it make gemma-check.",
        ]

    steps: list[str] = []
    if any(check.name == "Fireworks API key" and not check.ok for check in checks):
        steps.append("Create or copy a Fireworks API key from the Fireworks dashboard.")
    if any(check.name == "Fireworks models endpoint" and not check.ok for check in checks):
        steps.append("Confirm Fireworks credits are active and the API key has model-list access.")
    if any(check.name == "AMD Cloud credits" and not check.ok for check in checks):
        steps.append("Open the AMD Cloud console and confirm credits plus GPU quota, then set AMD_CLOUD_STATUS=active.")
    return steps


def normalize_base_url(url: str) -> str:
    normalized = url.strip().rstrip("/")
    parsed = urllib.parse.urlparse(normalized)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError(f"expected http(s) Fireworks base URL, got: {url}")
    if normalized.endswith("/v1"):
        return normalized
    return f"{normalized}/v1"


def join_url(base_url: str, path: str) -> str:
    return f"{base_url.rstrip('/')}/{path.lstrip('/')}"


def extract_model_ids(payload: dict[str, Any]) -> list[str]:
    data = payload.get("data")
    if not isinstance(data, list):
        return []
    return [item["id"] for item in data if isinstance(item, dict) and isinstance(item.get("id"), str)]


def get_models_json(url: str, api_key: str, timeout: float) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        headers={"authorization": f"Bearer {api_key}"},
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {body[:300]}") from exc


def write_report(path: Path, report: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
