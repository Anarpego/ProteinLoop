"""Smoke test the Docker Compose demo services."""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EVIDENCE_PATH = ROOT / "submission" / "docker-smoke-evidence.json"
SIMULATOR = "http://127.0.0.1:8000"
WEB = "http://127.0.0.1:4001"
TIMEOUT_SECONDS = 2.0


@dataclass(frozen=True)
class Check:
    name: str
    ok: bool
    detail: str = ""


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    checks: list[Check] = []

    try:
        checks.extend(check_simulator())
        checks.extend(check_web())
    except Exception as exc:  # noqa: BLE001 - smoke test should report any failure plainly.
        checks.append(Check("unexpected error", False, repr(exc)))

    for check in checks:
        mark = "ok" if check.ok else "FAIL"
        suffix = f" - {check.detail}" if check.detail else ""
        print(f"[{mark}] {check.name}{suffix}")

    failed = [check for check in checks if not check.ok]
    evidence = build_evidence(checks)
    if args.write_evidence:
        write_evidence(Path(args.evidence_file), evidence)
        print(f"wrote {Path(args.evidence_file).relative_to(ROOT)}")

    if failed:
        print(f"{len(failed)} smoke check(s) failed", file=sys.stderr)
        return 1

    print("docker smoke OK")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-evidence", action="store_true", help="Write submission/docker-smoke-evidence.json.")
    parser.add_argument("--evidence-file", default=str(DEFAULT_EVIDENCE_PATH))
    return parser.parse_args(argv)


def build_evidence(checks: list[Check]) -> dict[str, Any]:
    return {
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "ok": all(check.ok for check in checks),
        "simulator_url": SIMULATOR,
        "web_url": WEB,
        "checks": [asdict(check) for check in checks],
    }


def write_evidence(path: Path, evidence: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def check_simulator() -> list[Check]:
    checks: list[Check] = []

    health = get_json(f"{SIMULATOR}/health")
    checks.append(Check("simulator health", health.get("ok") is True))

    forecast = get_json(f"{SIMULATOR}/forecast/anomaly")["forecast"]
    checks.append(Check("anomaly forecast endpoint", forecast.get("risk_level") in {"stable", "warning", "critical"}))

    rlvr = get_json(f"{SIMULATOR}/rlvr/evaluation")["rlvr"]
    checks.append(Check("rlvr endpoint", rlvr.get("average_reward_delta", 0) > 0))

    training = get_json(f"{SIMULATOR}/rlvr/training")["training"]
    checks.append(Check("rlvr training endpoint", training.get("improvement", 0) > 0))

    reset = post_json(f"{SIMULATOR}/reset", {})
    checks.append(Check("reset endpoint", reset["state"]["day"] == 0))

    spike = post_json(f"{SIMULATOR}/scenario/ammonia_spike", {})
    checks.append(Check("ammonia spike endpoint", spike["state"]["ammonia_mg_l"] >= 3.0))

    safety = post_json(f"{SIMULATOR}/policy/safety_step", {})
    checks.append(
        Check(
            "safety recovery endpoint",
            safety["verification"]["ok"] is True and safety["state"]["day"] >= 1,
            f"reward={safety.get('reward')}",
        )
    )

    return checks


def check_web() -> list[Check]:
    operator = get_text(f"{WEB}/")
    producer = get_text(f"{WEB}/producer")

    operator_needles = [
        "Operator dashboard",
        "Run demo cascade",
        "RLVR reward verifier",
        "Policy search improvement",
        "Anomaly forecast",
        "Agentic intervention mission",
        "Sagents 0.9.0",
        "until_tool_success",
        "Human approval",
        "Your protein loop at a glance",
        "Waste in the water",
        "Self-healing mesh",
        "Physical DECT NR+ link",
        "Sequence #100",
        "1051223739",
        "1051239227",
    ]
    producer_needles = [
        "Producer decisions",
        "Approve",
        "Apply half",
        "Reject",
        "Offline fallback",
        "WhatsApp/SMS message",
        "Latest DECT NR+ link",
        "Sequence #100",
        "real radio",
        "Waste in the water",
    ]

    checks = [
        Check("operator dashboard route", all(needle in operator for needle in operator_needles)),
        Check("producer English route", all(needle in producer for needle in producer_needles)),
    ]

    return checks


def get_json(url: str) -> dict[str, Any]:
    return json.loads(get_text(url))


def post_json(url: str, payload: dict[str, Any]) -> dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={"content-type": "application/json"},
        method="POST",
    )
    return json.loads(open_url(request))


def get_text(url: str) -> str:
    return open_url(urllib.request.Request(url, method="GET"))


def open_url(request: urllib.request.Request) -> str:
    last_error: Exception | None = None
    for _attempt in range(10):
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
                return response.read().decode("utf-8")
        except (urllib.error.URLError, TimeoutError) as exc:
            last_error = exc
            time.sleep(0.25)
    raise RuntimeError(f"request failed: {request.full_url}: {last_error}")


if __name__ == "__main__":
    raise SystemExit(main())
