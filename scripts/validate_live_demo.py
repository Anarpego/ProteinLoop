"""Validate a public ProteinLoop demo URL."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any


DEFAULT_TIMEOUT_SECONDS = 5.0
RETRY_COUNT = 10

OPERATOR_NEEDLES = [
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

PRODUCER_NEEDLES = [
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


@dataclass(frozen=True)
class Check:
    name: str
    ok: bool
    detail: str = ""


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    base_url = args.base_url or os.environ.get("DEMO_URL")
    simulator_url = args.simulator_url or os.environ.get("SIMULATOR_PUBLIC_URL")

    if not base_url:
        print("DEMO_URL or --base-url is required", file=sys.stderr)
        return 2

    try:
        checks = check_live_demo(
            normalize_base_url(base_url),
            normalize_base_url(simulator_url) if simulator_url else None,
            args.timeout,
        )
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2
    except Exception as exc:  # noqa: BLE001 - validator should report any URL failure plainly.
        checks = [Check("unexpected error", False, repr(exc))]

    for check in checks:
        mark = "ok" if check.ok else "FAIL"
        suffix = f" - {check.detail}" if check.detail else ""
        print(f"[{mark}] {check.name}{suffix}")

    failed = [check for check in checks if not check.ok]
    if failed:
        print(f"{len(failed)} live demo check(s) failed", file=sys.stderr)
        return 1

    print("live demo OK")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", help="Public Phoenix app URL. Defaults to DEMO_URL.")
    parser.add_argument(
        "--simulator-url",
        help="Optional public simulator API URL. Defaults to SIMULATOR_PUBLIC_URL.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=DEFAULT_TIMEOUT_SECONDS,
        help=f"HTTP timeout in seconds. Default: {DEFAULT_TIMEOUT_SECONDS}.",
    )
    return parser.parse_args(argv)


def check_live_demo(base_url: str, simulator_url: str | None, timeout: float) -> list[Check]:
    checks = check_web(base_url, timeout)
    if simulator_url:
        checks.extend(check_simulator(simulator_url, timeout))
    return checks


def check_web(base_url: str, timeout: float) -> list[Check]:
    operator = get_text(join_url(base_url, "/"), timeout)
    producer = get_text(join_url(base_url, "/producer"), timeout)

    return [
        marker_check("operator dashboard route", operator, OPERATOR_NEEDLES),
        marker_check("producer English route", producer, PRODUCER_NEEDLES),
    ]


def check_simulator(simulator_url: str, timeout: float) -> list[Check]:
    health = get_json(join_url(simulator_url, "/health"), timeout)
    forecast = get_json(join_url(simulator_url, "/forecast/anomaly"), timeout).get("forecast", {})
    rlvr = get_json(join_url(simulator_url, "/rlvr/evaluation"), timeout).get("rlvr", {})
    training = get_json(join_url(simulator_url, "/rlvr/training"), timeout).get("training", {})

    return [
        Check("public simulator health", health.get("ok") is True),
        Check(
            "public simulator forecast",
            forecast.get("risk_level") in {"stable", "warning", "critical"},
        ),
        Check(
            "public simulator rlvr",
            rlvr.get("average_reward_delta", 0) > 0,
            f"delta={rlvr.get('average_reward_delta')}",
        ),
        Check(
            "public simulator rlvr training",
            training.get("improvement", 0) > 0,
            f"improvement={training.get('improvement')}",
        ),
    ]


def marker_check(name: str, text: str, needles: list[str]) -> Check:
    missing = [needle for needle in needles if needle not in text]
    return Check(name, not missing, f"missing: {', '.join(missing)}" if missing else "")


def normalize_base_url(url: str) -> str:
    normalized = url.strip().rstrip("/")
    parsed = urllib.parse.urlparse(normalized)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise ValueError(f"expected http(s) URL, got: {url}")
    return normalized


def join_url(base_url: str, path: str) -> str:
    return f"{base_url}/{path.lstrip('/')}"


def get_json(url: str, timeout: float) -> dict[str, Any]:
    return json.loads(get_text(url, timeout))


def get_text(url: str, timeout: float) -> str:
    request = urllib.request.Request(url, method="GET")
    last_error: Exception | None = None
    for _attempt in range(RETRY_COUNT):
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return response.read().decode("utf-8")
        except (urllib.error.URLError, TimeoutError) as exc:
            last_error = exc
            time.sleep(0.25)
    raise RuntimeError(f"request failed: {url}: {last_error}")


if __name__ == "__main__":
    raise SystemExit(main())
