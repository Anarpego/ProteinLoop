"""Validate the public demo Docker Compose profile."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COMPOSE = ROOT / "docker-compose.public.yml"

REQUIRED_SNIPPETS = [
    "services:",
    "simulator:",
    "web:",
    "restart: unless-stopped",
    'expose:\n      - "8000"',
    "PHX_HOST: ${PHX_HOST:?set PHX_HOST to the public hostname}",
    "SECRET_KEY_BASE: ${SECRET_KEY_BASE:?set SECRET_KEY_BASE}",
    'SIMULATOR_URL: "http://simulator:8000"',
    "GEMMA_ENDPOINT: ${GEMMA_ENDPOINT:-}",
    "GEMMA_MODEL: ${GEMMA_MODEL:-google/gemma-4-E2B-it}",
    'ports:\n      - "${PUBLIC_PORT:-80}:4000"',
    "proteinloop_traces:",
]

FORBIDDEN_SNIPPETS = [
    '"8000:8000"',
    "'8000:8000'",
    "- 8000:8000",
    'PHX_HOST: "localhost"',
    "proteinloop-docker-secret-key-base",
]


def main() -> int:
    checks = validate_profile(COMPOSE)

    for name, ok, detail in checks:
        mark = "ok" if ok else "FAIL"
        suffix = f" - {detail}" if detail else ""
        print(f"[{mark}] {name}{suffix}")

    failed = [check for check in checks if not check[1]]
    if failed:
        print(f"{len(failed)} public deploy check(s) failed", file=sys.stderr)
        return 1

    print("public deploy profile OK")
    return 0


def validate_profile(path: Path) -> list[tuple[str, bool, str]]:
    if not path.exists():
        return [("public compose file", False, "missing docker-compose.public.yml")]

    text = path.read_text(encoding="utf-8")
    checks: list[tuple[str, bool, str]] = [("public compose file", True, "")]

    missing = [snippet for snippet in REQUIRED_SNIPPETS if snippet not in text]
    checks.append(("required public compose settings", not missing, ", ".join(missing)))

    forbidden = [snippet for snippet in FORBIDDEN_SNIPPETS if snippet in text]
    checks.append(("local-only settings absent", not forbidden, ", ".join(forbidden)))

    checks.append(("simulator not publicly published", "simulator:\n    build: .\n    restart: unless-stopped\n    expose:" in text, ""))

    return checks


if __name__ == "__main__":
    raise SystemExit(main())
