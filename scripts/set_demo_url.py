"""Verify and set the lablab Application URL."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LABLAB = ROOT / "submission" / "lablab-submission.md"

sys.path.insert(0, str(ROOT))

from scripts.validate_live_demo import check_live_demo, normalize_base_url  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    try:
        demo_url = normalize_base_url(args.demo_url)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    if args.dry_run:
        print(f"would verify demo URL: {demo_url}")
        print(f"would update {LABLAB.relative_to(ROOT)}")
        return 0

    checks = check_live_demo(demo_url, None, args.timeout)
    for check in checks:
        mark = "ok" if check.ok else "FAIL"
        suffix = f" - {check.detail}" if check.detail else ""
        print(f"[{mark}] {check.name}{suffix}")

    failed = [check for check in checks if not check.ok]
    if failed:
        print(f"{len(failed)} live demo check(s) failed; Application URL not updated", file=sys.stderr)
        return 1

    update_application_url(LABLAB, demo_url)
    print(f"updated Application URL: {demo_url}")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("demo_url", help="Public demo URL to verify and write.")
    parser.add_argument("--dry-run", action="store_true", help="Preview without checking or writing.")
    parser.add_argument("--timeout", type=float, default=5.0)
    return parser.parse_args(argv)


def update_application_url(path: Path, demo_url: str) -> None:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(r"^(?P<header>## Application URL\s*\n\s*)(?P<value>\S+)\s*$", re.MULTILINE)

    if pattern.search(text):
        updated = pattern.sub(rf"\g<header>{demo_url}", text)
    else:
        updated = text.rstrip() + f"\n\n## Application URL\n\n{demo_url}\n"

    if not updated.endswith("\n"):
        updated += "\n"

    path.write_text(updated, encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
