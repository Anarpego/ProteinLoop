"""Daily deterministic simulator for the ProteinLoop ecosystem."""

from __future__ import annotations

from dataclasses import dataclass

from .actions import EcosystemAction
from .state import EcosystemState
from .verifier import SafetyVerifier, VerificationResult


class UnsafeActionError(ValueError):
    """Raised when the harness rejects a proposed action."""

    def __init__(self, result: VerificationResult):
        self.result = result
        super().__init__("; ".join(result.violations))


@dataclass
class StepResult:
    state: EcosystemState
    reward: float
    verification: VerificationResult

    def to_dict(self) -> dict[str, object]:
        return {
            "state": self.state.to_dict(),
            "reward": self.reward,
            "verification": self.verification.to_dict(),
        }


class EcosystemSimulator:
    """Mutable simulator wrapper used by CLI, tests, and the HTTP server."""

    def __init__(
        self,
        state: EcosystemState | None = None,
        verifier: SafetyVerifier | None = None,
    ) -> None:
        self.initial_state = state.clone() if state else EcosystemState()
        self.state = state.clone() if state else EcosystemState()
        self.verifier = verifier or SafetyVerifier()

    def reset(self, state: EcosystemState | None = None) -> EcosystemState:
        if state is not None:
            self.initial_state = state.clone()
        self.state = self.initial_state.clone()
        self.state.last_event = "reset"
        return self.state

    def apply_ammonia_spike(
        self,
        ammonia_mg_l: float = 4.6,
        oxygen_mg_l: float = 4.4,
    ) -> EcosystemState:
        self.state.ammonia_mg_l = ammonia_mg_l
        self.state.dissolved_oxygen_mg_l = oxygen_mg_l
        self.state.last_event = "ammonia_spike"
        return self.state

    def step(self, action: EcosystemAction, validate: bool = True) -> StepResult:
        verification = self.verifier.validate_action(self.state, action)
        if validate and not verification.ok:
            raise UnsafeActionError(verification)

        self.state = _evolve_one_day(self.state, action)
        return StepResult(
            state=self.state,
            reward=self.verifier.reward(self.state),
            verification=verification,
        )


def _evolve_one_day(
    previous: EcosystemState,
    action: EcosystemAction,
) -> EcosystemState:
    state = previous.clone()
    if state.collapsed:
        state.day += 1
        state.last_event = "collapsed_noop"
        return state

    water_exchange = _clamp(action.water_exchange_fraction, 0.0, 0.90)
    feed_kg = max(0.0, action.feed_kg)
    aeration_hours = _clamp(action.aeration_hours, 0.0, 24.0)
    duckweed_harvest = _clamp(action.duckweed_harvest_kg, 0.0, state.duckweed_kg)

    state.day += 1
    state.duckweed_kg -= duckweed_harvest

    # Water exchange is applied before biology for the day.
    state.ammonia_mg_l *= 1.0 - water_exchange
    state.nitrate_mg_l *= 1.0 - water_exchange
    state.dissolved_oxygen_mg_l += water_exchange * 1.8

    aquatic_biomass = state.aquatic_biomass_kg
    waste_ammonia = feed_kg * 0.75 + aquatic_biomass * 0.012
    nitrification_capacity = max(0.05, 0.34 + max(0.0, state.dissolved_oxygen_mg_l - 4.0) * 0.08)
    nitrified = min(state.ammonia_mg_l + waste_ammonia, nitrification_capacity)
    plant_ammonia_uptake = min(
        state.ammonia_mg_l + waste_ammonia - nitrified,
        state.duckweed_kg * 0.045 + state.plant_biomass_kg * 0.018,
    )

    state.ammonia_mg_l = max(
        0.02,
        state.ammonia_mg_l + waste_ammonia - nitrified - plant_ammonia_uptake,
    )

    plant_nitrate_uptake = state.plant_biomass_kg * 0.52 + state.duckweed_kg * 0.24
    state.nitrate_mg_l = max(
        0.0,
        state.nitrate_mg_l + nitrified * 22.0 - plant_nitrate_uptake,
    )

    oxygen_gain = 0.35 + aeration_hours * 0.22 + water_exchange * 1.6
    oxygen_use = aquatic_biomass * 0.085 + feed_kg * 0.85 + nitrified * 0.22
    state.dissolved_oxygen_mg_l = _clamp(
        state.dissolved_oxygen_mg_l + oxygen_gain - oxygen_use,
        0.4,
        9.2,
    )

    stress = _stress_index(state)
    growth_factor = max(0.0, 1.0 - stress * 0.22)
    state.fish_biomass_kg += feed_kg * 0.34 * growth_factor
    state.prawn_biomass_kg += feed_kg * 0.09 * growth_factor

    duckweed_growth = state.duckweed_kg * 0.28
    nitrate_limited_growth = min(duckweed_growth, max(0.0, state.nitrate_mg_l) * 0.018)
    state.duckweed_kg = _clamp(state.duckweed_kg + nitrate_limited_growth, 0.0, 12.0)

    plant_growth = min(0.18, state.nitrate_mg_l * 0.003) * growth_factor
    state.plant_biomass_kg += plant_growth

    duckweed_to_chickens = min(duckweed_harvest, 0.10 * state.chicken_count)
    egg_rate = 0.72 + duckweed_to_chickens * 0.18
    state.eggs_count += state.chicken_count * egg_rate

    # pH drifts mildly with nitrogen load and recovers with water exchange.
    state.ph = _clamp(
        state.ph - max(0.0, state.ammonia_mg_l - 1.0) * 0.012 + water_exchange * 0.05,
        6.2,
        8.4,
    )

    if _is_stressed(state):
        state.stress_days += 1
    else:
        state.stress_days = max(0, state.stress_days - 1)

    if _is_lethal(state) or state.stress_days >= 3:
        _apply_mortality(state)

    state.last_event = action.note or "daily_step"
    return state


def _is_stressed(state: EcosystemState) -> bool:
    return (
        state.ammonia_mg_l > 3.0
        or state.dissolved_oxygen_mg_l < 3.5
        or state.ph < 6.5
        or state.ph > 8.5
    )


def _is_lethal(state: EcosystemState) -> bool:
    return state.ammonia_mg_l > 5.5 or state.dissolved_oxygen_mg_l < 2.0


def _stress_index(state: EcosystemState) -> float:
    ammonia = max(0.0, state.ammonia_mg_l - 1.2) / 3.0
    oxygen = max(0.0, 5.0 - state.dissolved_oxygen_mg_l) / 3.0
    ph = max(0.0, 6.7 - state.ph, state.ph - 8.2) / 1.5
    return _clamp(ammonia + oxygen + ph, 0.0, 3.0)


def _apply_mortality(state: EcosystemState) -> None:
    state.collapsed = True
    state.mortality_events["fish"] += 1
    state.mortality_events["prawn"] += 1
    state.fish_biomass_kg *= 0.58
    state.prawn_biomass_kg *= 0.50
    state.last_event = "mortality_cascade"


def _clamp(value: float, lower: float, upper: float) -> float:
    return min(upper, max(lower, value))

