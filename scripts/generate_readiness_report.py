"""Generate a final submission readiness report."""

from __future__ import annotations

import datetime as dt
import subprocess
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
OUTPUT = SUBMISSION / "final-readiness-report.md"


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
    working_tree = git_text(["status", "--short"]) or "clean"

    evidence = [
        run_command("Unit tests", ["make", "test"]),
        run_command("CI workflow contract", ["make", "ci-check"]),
        run_command("Public deploy profile", ["make", "public-deploy-check"]),
        run_command("Gemma endpoint evidence", ["make", "gemma-check"]),
        run_command("Final submission readiness", ["make", "submission-ready-check"]),
        run_command("GitHub CLI authentication", ["gh", "auth", "status"]),
    ]

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
        f"Working tree: `{working_tree}`",
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
