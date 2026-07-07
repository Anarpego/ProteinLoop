"""Policies used for demos and regression tests."""

from __future__ import annotations

from collections.abc import Callable

from .actions import EcosystemAction
from .simulator import EcosystemSimulator
from .state import EcosystemState

Policy = Callable[[EcosystemState], EcosystemAction]


def naive_policy(state: EcosystemState) -> EcosystemAction:
    """A fixed routine that ignores water chemistry."""

    return EcosystemAction(
        feed_kg=0.42,
        aeration_hours=6.0,
        water_exchange_fraction=0.0,
        duckweed_harvest_kg=0.15 if state.duckweed_kg > 1.0 else 0.0,
        note="naive_routine",
    )


def safety_policy(state: EcosystemState) -> EcosystemAction:
    """Deterministic stand-in for the future LLM plus safety harness loop."""

    if state.ammonia_mg_l >= 3.0:
        return EcosystemAction(
            feed_kg=0.0,
            aeration_hours=24.0,
            water_exchange_fraction=0.30,
            duckweed_harvest_kg=0.0,
            note="critical_ammonia_recovery",
        )

    if state.ammonia_mg_l >= 1.5:
        return EcosystemAction(
            feed_kg=0.08,
            aeration_hours=18.0,
            water_exchange_fraction=0.15,
            duckweed_harvest_kg=0.0,
            note="ammonia_stabilization",
        )

    if state.dissolved_oxygen_mg_l < 5.0:
        return EcosystemAction(
            feed_kg=0.18,
            aeration_hours=18.0,
            water_exchange_fraction=0.05,
            duckweed_harvest_kg=0.0,
            note="oxygen_recovery",
        )

    max_feed = max(0.05, state.aquatic_biomass_kg * 0.024)
    duckweed_harvest = min(0.20, max(0.0, state.duckweed_kg - 1.5))
    return EcosystemAction(
        feed_kg=max_feed,
        aeration_hours=9.0,
        water_exchange_fraction=0.0,
        duckweed_harvest_kg=duckweed_harvest,
        note="balanced_growth",
    )


def run_policy(
    policy: Policy,
    days: int,
    spike_day: int | None = None,
    validate: bool = True,
) -> EcosystemSimulator:
    sim = EcosystemSimulator()
    for day in range(days):
        if spike_day is not None and day == spike_day:
            sim.apply_ammonia_spike()
        sim.step(policy(sim.state), validate=validate)
    return sim

