"""Deterministic RLVR-style evaluation batches for ProteinLoop policies."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .policies import naive_policy, run_policy, safety_policy
from .actions import EcosystemAction
from .state import EcosystemState


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


@dataclass(frozen=True)
class PolicyParameters:
    name: str
    routine_feed_fraction: float
    routine_aeration_hours: float
    routine_duckweed_harvest_kg: float
    warning_feed_kg: float
    warning_aeration_hours: float
    warning_water_exchange_fraction: float
    critical_water_exchange_fraction: float

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "routine_feed_fraction": self.routine_feed_fraction,
            "routine_aeration_hours": self.routine_aeration_hours,
            "routine_duckweed_harvest_kg": self.routine_duckweed_harvest_kg,
            "warning_feed_kg": self.warning_feed_kg,
            "warning_aeration_hours": self.warning_aeration_hours,
            "warning_water_exchange_fraction": self.warning_water_exchange_fraction,
            "critical_water_exchange_fraction": self.critical_water_exchange_fraction,
        }


@dataclass(frozen=True)
class TrainingIteration:
    iteration: int
    policy: PolicyParameters
    average_reward: float
    recovered_scenarios: int
    collapse_avoidance_rate: float
    best_so_far_reward: float
    best_so_far_policy: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "iteration": self.iteration,
            "policy": self.policy.to_dict(),
            "average_reward": self.average_reward,
            "recovered_scenarios": self.recovered_scenarios,
            "collapse_avoidance_rate": self.collapse_avoidance_rate,
            "best_so_far_reward": self.best_so_far_reward,
            "best_so_far_policy": self.best_so_far_policy,
        }


@dataclass(frozen=True)
class RLVRTrainingRun:
    verifier: str
    method: str
    baseline_policy: str
    best_policy: PolicyParameters
    iterations: tuple[TrainingIteration, ...]

    @property
    def iteration_count(self) -> int:
        return len(self.iterations)

    @property
    def initial_reward(self) -> float:
        return self.iterations[0].average_reward if self.iterations else 0.0

    @property
    def best_reward(self) -> float:
        return self.iterations[-1].best_so_far_reward if self.iterations else 0.0

    @property
    def improvement(self) -> float:
        return round(self.best_reward - self.initial_reward, 4)

    def to_dict(self) -> dict[str, Any]:
        return {
            "verifier": self.verifier,
            "method": self.method,
            "baseline_policy": self.baseline_policy,
            "best_policy": self.best_policy.to_dict(),
            "iteration_count": self.iteration_count,
            "initial_reward": self.initial_reward,
            "best_reward": self.best_reward,
            "improvement": self.improvement,
            "iterations": [iteration.to_dict() for iteration in self.iterations],
        }


DEFAULT_SCENARIOS: tuple[tuple[str, int, int | None], ...] = (
    ("routine_growth", 8, None),
    ("early_ammonia_spike", 8, 1),
    ("mid_cycle_ammonia_spike", 10, 4),
)

DEFAULT_POLICY_CANDIDATES: tuple[PolicyParameters, ...] = (
    PolicyParameters("seed_low_input", 0.018, 7.0, 0.08, 0.12, 14.0, 0.08, 0.20),
    PolicyParameters("more_air_less_feed", 0.020, 10.0, 0.10, 0.10, 18.0, 0.12, 0.25),
    PolicyParameters("balanced_recovery", 0.024, 9.0, 0.16, 0.08, 18.0, 0.15, 0.30),
    PolicyParameters("growth_biased", 0.030, 9.0, 0.18, 0.10, 18.0, 0.12, 0.25),
    PolicyParameters("aggressive_exchange", 0.024, 11.0, 0.16, 0.06, 20.0, 0.20, 0.30),
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


def train_policy(
    candidates: tuple[PolicyParameters, ...] = DEFAULT_POLICY_CANDIDATES,
    scenarios: tuple[tuple[str, int, int | None], ...] = DEFAULT_SCENARIOS,
) -> RLVRTrainingRun:
    """Run a deterministic verifier-guided policy search over fixed candidates."""

    best_reward = float("-inf")
    best_policy = candidates[0]
    iterations: list[TrainingIteration] = []

    for index, candidate in enumerate(candidates, start=1):
        evaluation = _evaluate_parameterized_policy(candidate, scenarios)
        average_reward = _average_candidate_reward(evaluation)

        if average_reward > best_reward:
            best_reward = average_reward
            best_policy = candidate

        iterations.append(
            TrainingIteration(
                iteration=index,
                policy=candidate,
                average_reward=average_reward,
                recovered_scenarios=evaluation.recovered_scenarios,
                collapse_avoidance_rate=evaluation.collapse_avoidance_rate,
                best_so_far_reward=round(best_reward, 4),
                best_so_far_policy=best_policy.name,
            )
        )

    return RLVRTrainingRun(
        verifier="proteinloop_sim.verifier.SafetyVerifier.reward",
        method="deterministic_candidate_search",
        baseline_policy=candidates[0].name,
        best_policy=best_policy,
        iterations=tuple(iterations),
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


def _evaluate_parameterized_policy(
    candidate: PolicyParameters,
    scenarios: tuple[tuple[str, int, int | None], ...],
) -> RLVREvaluation:
    policy = _policy_from_parameters(candidate)

    evaluated = tuple(
        EvaluationScenario(
            name=name,
            days=days,
            spike_day=spike_day,
            baseline=_score_policy("naive", days, spike_day, validate=False),
            candidate=_score_custom_policy(candidate.name, policy, days, spike_day),
        )
        for name, days, spike_day in scenarios
    )

    return RLVREvaluation(
        verifier="proteinloop_sim.verifier.SafetyVerifier.reward",
        baseline_policy="naive",
        candidate_policy=candidate.name,
        scenarios=evaluated,
    )


def _average_candidate_reward(evaluation: RLVREvaluation) -> float:
    if not evaluation.scenarios:
        return 0.0
    return round(
        sum(scenario.candidate.reward for scenario in evaluation.scenarios)
        / len(evaluation.scenarios),
        4,
    )


def _score_custom_policy(
    name: str,
    policy,
    days: int,
    spike_day: int | None,
) -> PolicyScore:
    sim = run_policy(policy, days=days, spike_day=spike_day, validate=True)
    state = sim.state

    return PolicyScore(
        name=name,
        reward=round(sim.verifier.reward(state), 4),
        collapsed=state.collapsed,
        final_ammonia_mg_l=round(state.ammonia_mg_l, 4),
        final_oxygen_mg_l=round(state.dissolved_oxygen_mg_l, 4),
        edible_biomass_kg=round(state.edible_biomass_kg, 4),
    )


def _policy_from_parameters(parameters: PolicyParameters):
    def policy(state: EcosystemState) -> EcosystemAction:
        if state.ammonia_mg_l >= 3.0:
            return EcosystemAction(
                feed_kg=0.0,
                aeration_hours=24.0,
                water_exchange_fraction=parameters.critical_water_exchange_fraction,
                duckweed_harvest_kg=0.0,
                note=f"{parameters.name}_critical_recovery",
            )

        if state.ammonia_mg_l >= 1.5:
            return EcosystemAction(
                feed_kg=parameters.warning_feed_kg,
                aeration_hours=parameters.warning_aeration_hours,
                water_exchange_fraction=parameters.warning_water_exchange_fraction,
                duckweed_harvest_kg=0.0,
                note=f"{parameters.name}_warning_recovery",
            )

        if state.dissolved_oxygen_mg_l < 5.0:
            return EcosystemAction(
                feed_kg=min(parameters.warning_feed_kg, 0.12),
                aeration_hours=parameters.warning_aeration_hours,
                water_exchange_fraction=min(parameters.warning_water_exchange_fraction, 0.10),
                duckweed_harvest_kg=0.0,
                note=f"{parameters.name}_oxygen_recovery",
            )

        max_feed = max(0.05, state.aquatic_biomass_kg * parameters.routine_feed_fraction)
        duckweed_harvest = min(
            parameters.routine_duckweed_harvest_kg,
            max(0.0, state.duckweed_kg - 1.5),
        )
        return EcosystemAction(
            feed_kg=max_feed,
            aeration_hours=parameters.routine_aeration_hours,
            water_exchange_fraction=0.0,
            duckweed_harvest_kg=duckweed_harvest,
            note=f"{parameters.name}_routine",
        )

    return policy
