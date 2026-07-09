"""Publish the local repo to public GitHub and update lablab copy."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LABLAB = ROOT / "submission" / "lablab-submission.md"


@dataclass(frozen=True)
class RepoRef:
    owner: str
    name: str

    @property
    def url(self) -> str:
        return f"https://github.com/{self.owner}/{self.name}"

    @property
    def clone_url(self) -> str:
        return f"{self.url}.git"

    @property
    def slug(self) -> str:
        return f"{self.owner}/{self.name}"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    try:
        repo = parse_repo(args.repository)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    commands = plan_commands(
        repo,
        origin_exists(ROOT),
        existing=args.existing,
        remote_url=args.remote_url,
    )

    if args.dry_run:
        print(f"public repo URL: {repo.url}")
        for command in commands:
            print("+ " + " ".join(command))
        print(f"+ update {LABLAB.relative_to(ROOT)}")
        return 0

    if gh_auth_required(commands):
        auth = run(["gh", "auth", "status"], ROOT)
        if auth.returncode != 0:
            print(auth.stderr or auth.stdout, file=sys.stderr)
            return auth.returncode

    for command in commands:
        result = run(command, ROOT)
        if result.returncode != 0:
            print(result.stderr or result.stdout, file=sys.stderr)
            return result.returncode

    update_submission_repo_url(LABLAB, repo.url)
    print(f"published {repo.url}")
    print(f"updated {LABLAB.relative_to(ROOT)}")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", help="GitHub repository in owner/name form.")
    parser.add_argument(
        "--existing",
        action="store_true",
        help="Use an already-created GitHub repository instead of gh repo create.",
    )
    parser.add_argument(
        "--remote-url",
        help="Remote URL for --existing mode. Defaults to the HTTPS clone URL.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print commands without running them.")
    return parser.parse_args(argv)


def parse_repo(value: str) -> RepoRef:
    if not re.match(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", value):
        raise ValueError("repository must be in owner/name form")
    owner, name = value.split("/", 1)
    return RepoRef(owner=owner, name=name)


def plan_commands(
    repo: RepoRef,
    has_origin: bool,
    existing: bool = False,
    remote_url: str | None = None,
) -> list[list[str]]:
    if has_origin:
        return [["git", "push", "-u", "origin", "main"]]

    if existing:
        return [
            ["git", "remote", "add", "origin", remote_url or repo.clone_url],
            ["git", "push", "-u", "origin", "main"],
        ]

    return [
        ["gh", "repo", "create", repo.slug, "--public", "--source", ".", "--remote", "origin"],
        ["git", "push", "-u", "origin", "main"],
    ]


def gh_auth_required(commands: list[list[str]]) -> bool:
    return any(command[:2] == ["gh", "repo"] for command in commands)


def origin_exists(root: Path) -> bool:
    result = run(["git", "config", "--get", "remote.origin.url"], root)
    return result.returncode == 0 and bool(result.stdout.strip())


def update_submission_repo_url(path: Path, repo_url: str) -> None:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(r"^Public GitHub Repository:\s*\S+\s*$", re.MULTILINE)
    replacement = f"Public GitHub Repository: {repo_url}"
    if pattern.search(text):
        updated = pattern.sub(replacement, text)
    else:
        updated = text.rstrip() + f"\n\n## Repository\n\n{replacement}\n"
    if not updated.endswith("\n"):
        updated += "\n"
    path.write_text(updated, encoding="utf-8")


def run(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, check=False, capture_output=True, text=True)


if __name__ == "__main__":
    raise SystemExit(main())
