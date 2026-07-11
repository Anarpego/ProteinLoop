"""Product-level metrics for AMD Gemma verifier-guided recovery evaluation."""

from __future__ import annotations

import math
from statistics import mean
from typing import Any


def build_scenario_record(
    name: str,
    initial_state: dict[str, Any],
    search: dict[str, Any],
    generation_latency_ms: list[float],
) -> dict[str, Any]:
    candidates = search.get("candidates") if isinstance(search.get("candidates"), list) else []
    first = next(
        (
            item
            for item in candidates
            if isinstance(item, dict) and item.get("source") == "amd_hosted_gemma"
        ),
        None,
    )
    selected = search.get("selected") if isinstance(search.get("selected"), dict) else None
    baseline = search.get("baseline") if isinstance(search.get("baseline"), dict) else {}
    control = next(
        (
            item
            for item in candidates
            if isinstance(item, dict) and item.get("source") == "control_unsafe"
        ),
        None,
    )

    first_accepted = bool(first and first.get("accepted") is True)
    selected_accepted = bool(selected and selected.get("accepted") is True)
    first_reward = numeric_reward(first) if first_accepted else None
    selected_reward = numeric_reward(selected) if selected_accepted else None
    baseline_reward = numeric_reward(baseline)
    aquatic_biomass = number(initial_state.get("fish_biomass_kg")) + number(
        initial_state.get("prawn_biomass_kg")
    )
    selected_final_state = selected.get("final_state") if selected else None
    selected_preserved_loop = bool(
        selected_accepted
        and isinstance(selected_final_state, dict)
        and selected_final_state.get("collapsed") is not True
    )

    return {
        "name": name,
        "initial_state": initial_state,
        "aquatic_biomass_kg": round(aquatic_biomass, 4),
        "generation_latency_ms": [round(number(value), 3) for value in generation_latency_ms],
        "first_proposal": first,
        "selected_plan": selected,
        "baseline": baseline,
        "candidate_count": search.get("candidate_count", len(candidates)),
        "model_candidate_count": sum(
            1
            for candidate in candidates
            if isinstance(candidate, dict) and candidate.get("source") == "amd_hosted_gemma"
        ),
        "safe_count": search.get("safe_count", 0),
        "rejected_count": search.get("rejected_count", 0),
        "parse_error_count": search.get("parse_error_count", 0),
        "weight_updates": search.get("weight_updates"),
        "first_proposal_safe": first_accepted,
        "selected_plan_safe": selected_accepted,
        "unsafe_control_rejected": bool(control and control.get("accepted") is False),
        "search_rescued_first_rejection": bool(not first_accepted and selected_accepted),
        "search_improved_first": bool(
            selected_accepted
            and (
                not first_accepted
                or (
                    first_reward is not None
                    and selected_reward is not None
                    and selected_reward > first_reward
                )
            )
        ),
        "reward_delta_vs_first": reward_delta(selected_reward, first_reward),
        "reward_delta_vs_naive": reward_delta(selected_reward, baseline_reward),
        "protected_aquatic_biomass_kg": round(aquatic_biomass, 4)
        if selected_preserved_loop
        else 0.0,
    }


def summarize_product_evaluation(records: list[dict[str, Any]]) -> dict[str, Any]:
    scenario_count = len(records)
    if scenario_count == 0:
        return empty_summary()

    first_safe_count = sum(1 for item in records if item.get("first_proposal_safe") is True)
    selected_safe_count = sum(1 for item in records if item.get("selected_plan_safe") is True)
    first_deltas = numeric_values(records, "reward_delta_vs_first")
    naive_deltas = numeric_values(records, "reward_delta_vs_naive")
    latencies = [
        number(value)
        for item in records
        for value in item.get("generation_latency_ms", [])
        if is_number(value)
    ]
    controls = [item.get("unsafe_control_rejected") is True for item in records]
    first_safe_rate = first_safe_count / scenario_count
    selected_safe_rate = selected_safe_count / scenario_count

    return {
        "scenario_count": scenario_count,
        "model_candidate_count": sum(
            int(item.get("model_candidate_count", 0)) for item in records
        ),
        "first_proposal_safe_count": first_safe_count,
        "first_proposal_safe_rate": round(first_safe_rate, 4),
        "selected_plan_safe_count": selected_safe_count,
        "selected_plan_safe_rate": round(selected_safe_rate, 4),
        "safe_rate_lift": round(selected_safe_rate - first_safe_rate, 4),
        "search_rescue_count": sum(
            1 for item in records if item.get("search_rescued_first_rejection") is True
        ),
        "search_improvement_count": sum(
            1 for item in records if item.get("search_improved_first") is True
        ),
        "reward_comparison_count": len(first_deltas),
        "mean_reward_delta_vs_first": rounded_mean(first_deltas),
        "mean_reward_delta_vs_naive": rounded_mean(naive_deltas),
        "protected_aquatic_biomass_kg": round(
            sum(number(item.get("protected_aquatic_biomass_kg")) for item in records), 4
        ),
        "unsafe_control_rejection_rate": round(sum(controls) / scenario_count, 4),
        "generation_latency_ms": {
            "sample_count": len(latencies),
            "p50": percentile(latencies, 0.50),
            "p95": percentile(latencies, 0.95),
        },
    }


def reward_delta(selected_reward: float | None, comparison_reward: float | None) -> float | None:
    if selected_reward is None or comparison_reward is None:
        return None
    return round(selected_reward - comparison_reward, 4)


def numeric_reward(outcome: dict[str, Any] | None) -> float | None:
    if not isinstance(outcome, dict) or not is_number(outcome.get("reward")):
        return None
    return float(outcome["reward"])


def numeric_values(records: list[dict[str, Any]], key: str) -> list[float]:
    return [float(item[key]) for item in records if is_number(item.get(key))]


def rounded_mean(values: list[float]) -> float | None:
    return round(mean(values), 4) if values else None


def percentile(values: list[float], percentile_value: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    position = (len(ordered) - 1) * percentile_value
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return round(ordered[lower], 3)
    weight = position - lower
    return round(ordered[lower] * (1 - weight) + ordered[upper] * weight, 3)


def number(value: Any) -> float:
    return float(value) if is_number(value) else 0.0


def is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def empty_summary() -> dict[str, Any]:
    return {
        "scenario_count": 0,
        "model_candidate_count": 0,
        "first_proposal_safe_count": 0,
        "first_proposal_safe_rate": 0.0,
        "selected_plan_safe_count": 0,
        "selected_plan_safe_rate": 0.0,
        "safe_rate_lift": 0.0,
        "search_rescue_count": 0,
        "search_improvement_count": 0,
        "reward_comparison_count": 0,
        "mean_reward_delta_vs_first": None,
        "mean_reward_delta_vs_naive": None,
        "protected_aquatic_biomass_kg": 0.0,
        "unsafe_control_rejection_rate": 0.0,
        "generation_latency_ms": {"sample_count": 0, "p50": None, "p95": None},
    }
