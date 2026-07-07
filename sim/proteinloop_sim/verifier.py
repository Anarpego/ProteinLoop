"""Deterministic action verifier and reward function."""

from __future__ import annotations

from dataclasses import dataclass

from .actions import EcosystemAction
from .state import EcosystemState


@dataclass(frozen=True)
class VerificationResult:
    ok: bool
    violations: tuple[str, ...] = ()
    warnings: tuple[str, ...] = ()

    def to_dict(self) -> dict[str, object]:
        return {
            "ok": self.ok,
            "violations": list(self.violations),
            "warnings": list(self.warnings),
        }


class SafetyVerifier:
    """Rules that make the simulator usable as a harness/RLVR verifier."""

    max_feed_fraction_of_biomass = 0.035
    max_water_exchange_fraction = 0.30
    min_duckweed_reserve_kg = 0.50
    ammonia_warning_mg_l = 1.5
    ammonia_critical_mg_l = 3.0
    oxygen_warning_mg_l = 5.0
    oxygen_critical_mg_l = 3.5

    def validate_action(
        self,
        state: EcosystemState,
        action: EcosystemAction,
    ) -> VerificationResult:
        violations: list[str] = []
        warnings: list[str] = []

        if state.collapsed:
            violations.append("ecosystem is collapsed; reset or start recovery scenario")

        checked_values = {
            "feed_kg": action.feed_kg,
            "aeration_hours": action.aeration_hours,
            "water_exchange_fraction": action.water_exchange_fraction,
            "duckweed_harvest_kg": action.duckweed_harvest_kg,
        }
        for field, value in checked_values.items():
            if value < 0:
                violations.append(f"{field} cannot be negative")

        max_feed = max(0.05, state.aquatic_biomass_kg * self.max_feed_fraction_of_biomass)
        if action.feed_kg > max_feed:
            violations.append(
                f"feed_kg {action.feed_kg:.3f} exceeds safe daily limit {max_feed:.3f}"
            )

        if (
            state.ammonia_mg_l >= self.ammonia_critical_mg_l
            and action.feed_kg > 0.10
        ):
            violations.append(
                "feed must stay at or below 0.10 kg/day during critical ammonia"
            )

        if action.aeration_hours > 24:
            violations.append("aeration_hours cannot exceed 24")

        if action.water_exchange_fraction > self.max_water_exchange_fraction:
            violations.append(
                "water_exchange_fraction cannot exceed "
                f"{self.max_water_exchange_fraction:.2f}"
            )

        available_duckweed = max(0.0, state.duckweed_kg - self.min_duckweed_reserve_kg)
        if action.duckweed_harvest_kg > available_duckweed:
            violations.append(
                "duckweed_harvest_kg exceeds available biomass after reserve "
                f"({available_duckweed:.3f} kg)"
            )

        if state.ammonia_mg_l >= self.ammonia_warning_mg_l:
            warnings.append("ammonia is elevated; reduce feed and increase biofiltration")

        if state.dissolved_oxygen_mg_l < self.oxygen_warning_mg_l:
            warnings.append("dissolved oxygen is low; increase aeration")

        return VerificationResult(
            ok=not violations,
            violations=tuple(violations),
            warnings=tuple(warnings),
        )

    def reward(self, state: EcosystemState) -> float:
        survival = 120.0 if not state.collapsed else -220.0
        biomass = state.edible_biomass_kg * 4.0
        eggs = state.eggs_count * 0.25
        duckweed = state.duckweed_kg * 1.2

        ammonia_penalty = max(0.0, state.ammonia_mg_l - 0.8) * 35.0
        oxygen_penalty = max(0.0, 5.5 - state.dissolved_oxygen_mg_l) * 28.0
        ph_penalty = max(0.0, 6.7 - state.ph, state.ph - 8.2) * 25.0
        stress_penalty = state.stress_days * 18.0
        mortality_penalty = sum(state.mortality_events.values()) * 60.0

        return round(
            survival
            + biomass
            + eggs
            + duckweed
            - ammonia_penalty
            - oxygen_penalty
            - ph_penalty
            - stress_penalty
            - mortality_penalty,
            4,
        )

    def is_terminal(self, state: EcosystemState, target_day: int = 180) -> bool:
        return state.collapsed or state.day >= target_day

