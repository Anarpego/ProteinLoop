"""Structured intervention actions for the ProteinLoop simulator."""

from __future__ import annotations

from dataclasses import dataclass
from math import isfinite
from typing import Any


@dataclass(frozen=True)
class EcosystemAction:
    """One day of proposed ecosystem interventions."""

    feed_kg: float = 0.35
    aeration_hours: float = 8.0
    water_exchange_fraction: float = 0.0
    duckweed_harvest_kg: float = 0.0
    note: str = ""

    @classmethod
    def from_dict(cls, payload: dict[str, Any] | None) -> "EcosystemAction":
        if payload is None:
            return cls()
        return cls(
            feed_kg=_number(payload.get("feed_kg", cls.feed_kg), "feed_kg"),
            aeration_hours=_number(
                payload.get("aeration_hours", cls.aeration_hours),
                "aeration_hours",
            ),
            water_exchange_fraction=_number(
                payload.get(
                    "water_exchange_fraction",
                    cls.water_exchange_fraction,
                ),
                "water_exchange_fraction",
            ),
            duckweed_harvest_kg=_number(
                payload.get("duckweed_harvest_kg", cls.duckweed_harvest_kg),
                "duckweed_harvest_kg",
            ),
            note=str(payload.get("note", "")),
        )

    def to_dict(self) -> dict[str, float | str]:
        return {
            "feed_kg": self.feed_kg,
            "aeration_hours": self.aeration_hours,
            "water_exchange_fraction": self.water_exchange_fraction,
            "duckweed_harvest_kg": self.duckweed_harvest_kg,
            "note": self.note,
        }


def _number(value: Any, field: str) -> float:
    try:
        parsed = float(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{field} must be a number") from exc

    if not isfinite(parsed):
        raise ValueError(f"{field} must be finite")
    return parsed

