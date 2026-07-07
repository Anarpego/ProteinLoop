"""Smoke test the Docker Compose demo services."""

from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any


SIMULATOR = "http://127.0.0.1:8000"
WEB = "http://127.0.0.1:4001"
TIMEOUT_SECONDS = 2.0


@dataclass(frozen=True)
class Check:
    name: str
    ok: bool
    detail: str = ""


def main() -> int:
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
    if failed:
        print(f"{len(failed)} smoke check(s) failed", file=sys.stderr)
        return 1

    print("docker smoke OK")
    return 0


def check_simulator() -> list[Check]:
    checks: list[Check] = []

    health = get_json(f"{SIMULATOR}/health")
    checks.append(Check("simulator health", health.get("ok") is True))

    forecast = get_json(f"{SIMULATOR}/forecast/anomaly")["forecast"]
    checks.append(Check("anomaly forecast endpoint", forecast.get("risk_level") in {"stable", "warning", "critical"}))

    rlvr = get_json(f"{SIMULATOR}/rlvr/evaluation")["rlvr"]
    checks.append(Check("rlvr endpoint", rlvr.get("average_reward_delta", 0) > 0))

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
        "Anomaly forecast",
        "Sagents loop contract",
        "Spanish HITL approval",
        "Self-healing mesh",
    ]
    producer_needles = ["Productor", "Aprobar", "Solo mitad", "Rechazar", "Respaldo offline"]

    checks = [
        Check("operator dashboard route", all(needle in operator for needle in operator_needles)),
        Check("producer Spanish route", all(needle in producer for needle in producer_needles)),
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
