"""Run the final generated-artifact sequence before lablab submission."""

from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Sequence


ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class FinalizeStep:
    name: str
    command: tuple[str, ...]


FINALIZE_STEPS = [
    FinalizeStep("Docker smoke evidence", ("make", "docker-smoke")),
    FinalizeStep("Structured lablab form", ("make", "submission-form")),
    FinalizeStep("Upload bundle before report", ("make", "submission-bundle")),
    FinalizeStep("Final readiness report", ("make", "readiness-report")),
    FinalizeStep("Upload bundle with final report", ("make", "submission-bundle")),
    FinalizeStep("Submission artifact validation", ("make", "submission-check")),
    FinalizeStep("Final submission readiness", ("make", "submission-ready-check")),
]

Runner = Callable[[Sequence[str]], int]


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    return run_steps(FINALIZE_STEPS, dry_run=args.dry_run)


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Print commands without running them.")
    return parser.parse_args(argv)


def run_steps(
    steps: list[FinalizeStep],
    *,
    dry_run: bool = False,
    runner: Runner | None = None,
) -> int:
    runner = runner or run_command
    for step in steps:
        print(f"== {step.name} ==")
        print("+ " + shlex.join(step.command))
        if dry_run:
            continue

        returncode = runner(step.command)
        if returncode != 0:
            print(f"{step.name} failed with exit {returncode}", file=sys.stderr)
            return returncode

    print("submission finalization OK")
    return 0


def run_command(command: Sequence[str]) -> int:
    return subprocess.run(command, cwd=ROOT, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
