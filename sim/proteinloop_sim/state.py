"""State contract for the ProteinLoop ecosystem."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class EcosystemState:
    """JSON-compatible daily ecosystem snapshot."""

    day: int = 0
    water_volume_l: float = 1000.0
    ammonia_mg_l: float = 0.35
    nitrate_mg_l: float = 35.0
    dissolved_oxygen_mg_l: float = 6.8
    ph: float = 7.2
    temperature_c: float = 26.0
    fish_biomass_kg: float = 12.0
    prawn_biomass_kg: float = 2.5
    duckweed_kg: float = 3.0
    plant_biomass_kg: float = 5.0
    chicken_count: int = 6
    eggs_count: float = 0.0
    stress_days: int = 0
    collapsed: bool = False
    mortality_events: dict[str, int] = field(
        default_factory=lambda: {"fish": 0, "prawn": 0, "chicken": 0}
    )
    last_event: str = "initialized"

    @property
    def aquatic_biomass_kg(self) -> float:
        return self.fish_biomass_kg + self.prawn_biomass_kg

    @property
    def edible_biomass_kg(self) -> float:
        return self.fish_biomass_kg + self.prawn_biomass_kg + self.plant_biomass_kg

    def clone(self) -> "EcosystemState":
        return EcosystemState.from_dict(self.to_dict())

    def to_dict(self) -> dict[str, Any]:
        return {
            "day": self.day,
            "water_volume_l": round(self.water_volume_l, 3),
            "ammonia_mg_l": round(self.ammonia_mg_l, 4),
            "nitrate_mg_l": round(self.nitrate_mg_l, 4),
            "dissolved_oxygen_mg_l": round(self.dissolved_oxygen_mg_l, 4),
            "ph": round(self.ph, 4),
            "temperature_c": round(self.temperature_c, 4),
            "fish_biomass_kg": round(self.fish_biomass_kg, 4),
            "prawn_biomass_kg": round(self.prawn_biomass_kg, 4),
            "duckweed_kg": round(self.duckweed_kg, 4),
            "plant_biomass_kg": round(self.plant_biomass_kg, 4),
            "chicken_count": self.chicken_count,
            "eggs_count": round(self.eggs_count, 4),
            "stress_days": self.stress_days,
            "collapsed": self.collapsed,
            "mortality_events": dict(self.mortality_events),
            "last_event": self.last_event,
            "aquatic_biomass_kg": round(self.aquatic_biomass_kg, 4),
            "edible_biomass_kg": round(self.edible_biomass_kg, 4),
        }

    @classmethod
    def from_dict(cls, payload: dict[str, Any]) -> "EcosystemState":
        mortality = payload.get("mortality_events") or {}
        return cls(
            day=int(payload.get("day", 0)),
            water_volume_l=float(payload.get("water_volume_l", 1000.0)),
            ammonia_mg_l=float(payload.get("ammonia_mg_l", 0.35)),
            nitrate_mg_l=float(payload.get("nitrate_mg_l", 35.0)),
            dissolved_oxygen_mg_l=float(
                payload.get("dissolved_oxygen_mg_l", 6.8)
            ),
            ph=float(payload.get("ph", 7.2)),
            temperature_c=float(payload.get("temperature_c", 26.0)),
            fish_biomass_kg=float(payload.get("fish_biomass_kg", 12.0)),
            prawn_biomass_kg=float(payload.get("prawn_biomass_kg", 2.5)),
            duckweed_kg=float(payload.get("duckweed_kg", 3.0)),
            plant_biomass_kg=float(payload.get("plant_biomass_kg", 5.0)),
            chicken_count=int(payload.get("chicken_count", 6)),
            eggs_count=float(payload.get("eggs_count", 0.0)),
            stress_days=int(payload.get("stress_days", 0)),
            collapsed=bool(payload.get("collapsed", False)),
            mortality_events={
                "fish": int(mortality.get("fish", 0)),
                "prawn": int(mortality.get("prawn", 0)),
                "chicken": int(mortality.get("chicken", 0)),
            },
            last_event=str(payload.get("last_event", "loaded")),
        )

