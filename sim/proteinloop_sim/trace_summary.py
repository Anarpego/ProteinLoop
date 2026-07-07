"""Summarize ProteinLoop harness JSONL traces."""

from __future__ import annotations

from dataclasses import dataclass, field
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class TraceSummary:
    path: str
    total: int = 0
    accepted: int = 0
    rejected: int = 0
    average_accepted_reward: float | None = None
    provider_counts: dict[str, int] = field(default_factory=dict)
    latest_violations: tuple[str, ...] = ()

    def to_dict(self) -> dict[str, Any]:
        return {
            "path": self.path,
            "total": self.total,
            "accepted": self.accepted,
            "rejected": self.rejected,
            "average_accepted_reward": self.average_accepted_reward,
            "provider_counts": dict(self.provider_counts),
            "latest_violations": list(self.latest_violations),
        }


def summarize_trace_file(path: str | Path) -> TraceSummary:
    trace_path = Path(path)
    if not trace_path.exists():
        return TraceSummary(path=str(trace_path))

    entries = list(_read_entries(trace_path))
    accepted_entries = [entry for entry in entries if entry.get("accepted") is True]
    rejected_entries = [entry for entry in entries if entry.get("accepted") is not True]
    rewards = [
        float(entry["reward"])
        for entry in accepted_entries
        if isinstance(entry.get("reward"), int | float)
    ]

    provider_counts: dict[str, int] = {}
    for entry in entries:
        provider = str(entry.get("provider", "unknown"))
        provider_counts[provider] = provider_counts.get(provider, 0) + 1

    latest_violations: tuple[str, ...] = ()
    for entry in reversed(entries):
        violations = entry.get("verification", {}).get("violations") or []
        if violations:
            latest_violations = tuple(str(violation) for violation in violations)
            break

    average_reward = round(sum(rewards) / len(rewards), 4) if rewards else None

    return TraceSummary(
        path=str(trace_path),
        total=len(entries),
        accepted=len(accepted_entries),
        rejected=len(rejected_entries),
        average_accepted_reward=average_reward,
        provider_counts=provider_counts,
        latest_violations=latest_violations,
    )


def _read_entries(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(entry, dict):
                yield entry

