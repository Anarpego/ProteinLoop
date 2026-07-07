"""Deterministic RLVR-style evaluation batches for ProteinLoop policies."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .policies import naive_policy, run_policy, safety_policy


@dataclass(frozen=True)
class PolicyScore:
    name: str
    reward: float
    collapsed: bool
    final_ammonia_mg_l: float
    final_oxygen_mg_l: float
    edible_biomass_kg: float

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "reward": self.reward,
            "collapsed": self.collapsed,
            "final_ammonia_mg_l": self.final_ammonia_mg_l,
            "final_oxygen_mg_l": self.final_oxygen_mg_l,
            "edible_biomass_kg": self.edible_biomass_kg,
        }


@dataclass(frozen=True)
class EvaluationScenario:
    name: str
    days: int
    spike_day: int | None
    baseline: PolicyScore
    candidate: PolicyScore

    @property
    def reward_delta(self) -> float:
        return round(self.candidate.reward - self.baseline.reward, 4)

    @property
    def recovered(self) -> bool:
        return self.baseline.collapsed and not self.candidate.collapsed

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "days": self.days,
            "spike_day": self.spike_day,
            "baseline": self.baseline.to_dict(),
            "candidate": self.candidate.to_dict(),
            "reward_delta": self.reward_delta,
            "recovered": self.recovered,
        }


@dataclass(frozen=True)
class RLVREvaluation:
    verifier: str
    baseline_policy: str
    candidate_policy: str
    scenarios: tuple[EvaluationScenario, ...]

    @property
    def average_reward_delta(self) -> float:
        if not self.scenarios:
            return 0.0
        return round(sum(scenario.reward_delta for scenario in self.scenarios) / len(self.scenarios), 4)

    @property
    def recovered_scenarios(self) -> int:
        return sum(1 for scenario in self.scenarios if scenario.recovered)

    @property
    def collapse_avoidance_rate(self) -> float:
        baseline_collapses = sum(1 for scenario in self.scenarios if scenario.baseline.collapsed)
        if baseline_collapses == 0:
            return 1.0
        return round(self.recovered_scenarios / baseline_collapses, 4)

    def to_dict(self) -> dict[str, Any]:
        return {
            "verifier": self.verifier,
            "baseline_policy": self.baseline_policy,
            "candidate_policy": self.candidate_policy,
            "scenario_count": len(self.scenarios),
            "average_reward_delta": self.average_reward_delta,
            "recovered_scenarios": self.recovered_scenarios,
            "collapse_avoidance_rate": self.collapse_avoidance_rate,
            "scenarios": [scenario.to_dict() for scenario in self.scenarios],
        }


DEFAULT_SCENARIOS: tuple[tuple[str, int, int | None], ...] = (
    ("routine_growth", 8, None),
    ("early_ammonia_spike", 8, 1),
    ("mid_cycle_ammonia_spike", 10, 4),
)


def evaluate_policies(
    scenarios: tuple[tuple[str, int, int | None], ...] = DEFAULT_SCENARIOS,
) -> RLVREvaluation:
    """Score baseline and candidate policies with the simulator reward verifier."""

    evaluated = tuple(
        EvaluationScenario(
            name=name,
            days=days,
            spike_day=spike_day,
            baseline=_score_policy("naive", days, spike_day, validate=False),
            candidate=_score_policy("safety", days, spike_day, validate=True),
        )
        for name, days, spike_day in scenarios
    )

    return RLVREvaluation(
        verifier="proteinloop_sim.verifier.SafetyVerifier.reward",
        baseline_policy="naive",
        candidate_policy="safety",
        scenarios=evaluated,
    )


def _score_policy(name: str, days: int, spike_day: int | None, validate: bool) -> PolicyScore:
    policy = naive_policy if name == "naive" else safety_policy
    sim = run_policy(policy, days=days, spike_day=spike_day, validate=validate)
    state = sim.state

    return PolicyScore(
        name=name,
        reward=round(sim.verifier.reward(state), 4),
        collapsed=state.collapsed,
        final_ammonia_mg_l=round(state.ammonia_mg_l, 4),
        final_oxygen_mg_l=round(state.dissolved_oxygen_mg_l, 4),
        edible_biomass_kg=round(state.edible_biomass_kg, 4),
    )
