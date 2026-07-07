"""Validate the GitHub Actions workflow contract for the public repo."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "ci.yml"

REQUIRED_SNIPPETS = [
    "name: ProteinLoop CI",
    "push:",
    "pull_request:",
    "workflow_dispatch:",
    "runs-on: ubuntu-24.04",
    "actions/checkout@v7.0.0",
    "actions/setup-python@v6.3.0",
    'python-version: "3.11"',
    "erlef/setup-beam@v1.24.1",
    'elixir-version: "1.20.1"',
    'otp-version: "28"',
    "docker/setup-buildx-action@v4.2.0",
    "make test",
    "mix deps.get",
    "mix format --check-formatted",
    "mix test",
    "make submission-check",
    "docker compose build",
    "docker compose up -d",
    "python3 scripts/docker_smoke_test.py",
    "docker compose logs --no-color",
    "docker compose down -v",
]


def main() -> int:
    if not WORKFLOW.exists():
        print("missing: .github/workflows/ci.yml", file=sys.stderr)
        return 1

    workflow = WORKFLOW.read_text(encoding="utf-8")
    missing = [snippet for snippet in REQUIRED_SNIPPETS if snippet not in workflow]
    if missing:
        for snippet in missing:
            print(f"missing workflow snippet: {snippet}", file=sys.stderr)
        return 1

    if "docker-compose.gemma-rocm.yml" in workflow or "amd-gemma" in workflow:
        print("CI must not require the AMD Gemma ROCm profile", file=sys.stderr)
        return 1

    print("ci workflow OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
