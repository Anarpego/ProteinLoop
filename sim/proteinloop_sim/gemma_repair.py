"""Verifier-feedback repair and expanded AMD Gemma evaluation metrics."""

from __future__ import annotations

import math
from copy import deepcopy
from statistics import mean
from typing import Any, Callable

from .actions import EcosystemAction
from .gemma_search import evaluate_action
from .state import EcosystemState
from .verifier import SafetyVerifier


RevisionFunction = Callable[[dict[str, Any]], dict[str, Any]]

_ACTION_KEYS = (
    "feed_kg",
    "aeration_hours",
    "water_exchange_fraction",
    "duckweed_harvest_kg",
    "note",
)

_SIMULATED_COLLAPSE_VIOLATION = (
    "simulated action collapses the ecosystem; revise it to preserve the protein loop"
)

_VARIANTS: tuple[dict[str, Any], ...] = (
    {"label": "nominal", "ammonia_delta": 0.0, "oxygen_delta": 0.0},
    {
        "label": "high aquatic load",
        "ammonia_delta": 0.25,
        "oxygen_delta": -0.25,
        "aquatic_factor": 1.08,
        "duckweed_factor": 0.9,
    },
    {
        "label": "low biological reserve",
        "ammonia_delta": 0.1,
        "oxygen_delta": -0.1,
        "duckweed_factor": 0.65,
        "plant_factor": 0.85,
        "stress_delta": 1,
    },
    {
        "label": "power-limited aeration",
        "ammonia_delta": 0.35,
        "oxygen_delta": -0.45,
        "temperature_delta": 1.0,
        "stress_delta": 1,
    },
)


def build_verifier_feedback(
    state: EcosystemState,
    rejected_outcome: dict[str, Any],
    repair_attempt: int,
) -> dict[str, Any]:
    """Build a credential-free correction contract from deterministic verifier output."""

    verifier = SafetyVerifier()
    dynamic_feed_limit = max(
        0.05,
        state.aquatic_biomass_kg * verifier.max_feed_fraction_of_biomass,
    )
    if state.collapsed:
        effective_feed_limit = 0.0
    elif state.ammonia_mg_l >= verifier.ammonia_critical_mg_l:
        effective_feed_limit = min(dynamic_feed_limit, 0.10)
    else:
        effective_feed_limit = dynamic_feed_limit

    violations = [str(value) for value in rejected_outcome.get("violations") or []]
    violations.extend(
        str(value) for value in rejected_outcome.get("product_violations") or []
    )

    return {
        "schema_version": 1,
        "repair_attempt": int(repair_attempt),
        "current_state": state.to_dict(),
        "rejected_action": safe_action_payload(rejected_outcome.get("action")),
        "violations": violations,
        "warnings": [str(value) for value in rejected_outcome.get("warnings") or []],
        "simulated_outcome": {
            "verifier_accepted": rejected_outcome.get("accepted") is True,
            "product_safe": rejected_outcome.get("product_safe") is True,
            "collapsed": bool(
                isinstance(rejected_outcome.get("final_state"), dict)
                and rejected_outcome["final_state"].get("collapsed") is True
            ),
            "reward": rejected_outcome.get("reward"),
        },
        "hard_limits": {
            "feed_kg_min": 0.0,
            "feed_kg_max": round(effective_feed_limit, 4),
            "aeration_hours_min": 0.0,
            "aeration_hours_max": 24.0,
            "water_exchange_fraction_min": 0.0,
            "water_exchange_fraction_max": verifier.max_water_exchange_fraction,
            "duckweed_harvest_kg_min": 0.0,
            "duckweed_harvest_kg_max": round(
                max(0.0, state.duckweed_kg - verifier.min_duckweed_reserve_kg),
                4,
            ),
        },
        "required_output": {
            "type": "json_object",
            "numeric_fields": list(_ACTION_KEYS[:-1]),
            "text_fields": ["note"],
        },
    }


def run_verifier_feedback_repair(
    state: EcosystemState,
    initial_payload: dict[str, Any],
    revise: RevisionFunction,
    *,
    max_repairs: int = 3,
) -> dict[str, Any]:
    """Verify a proposal and request bounded revisions until one is safe."""

    if not isinstance(max_repairs, int) or isinstance(max_repairs, bool) or max_repairs < 0:
        raise ValueError("max_repairs must be a non-negative integer")

    attempts: list[dict[str, Any]] = []
    payload = initial_payload
    initial_safe = False

    for attempt_index in range(max_repairs + 1):
        phase = "initial" if attempt_index == 0 else "repair"
        outcome = evaluate_payload(
            state,
            payload,
            source="amd_hosted_gemma" if attempt_index == 0 else "amd_hosted_gemma_repair",
            strategy=(
                "initial recovery proposal"
                if attempt_index == 0
                else f"verifier-feedback repair {attempt_index}"
            ),
        )
        attempt = {
            "attempt_index": attempt_index,
            "phase": phase,
            "outcome": outcome,
        }
        attempts.append(attempt)

        if attempt_index == 0:
            initial_safe = outcome.get("product_safe") is True

        if outcome.get("product_safe") is True:
            return repair_result(
                attempts,
                selected=outcome,
                initial_safe=initial_safe,
                max_repairs=max_repairs,
                stopped_reason=(
                    "safe_initial_proposal"
                    if attempt_index == 0
                    else "safe_model_revision"
                ),
            )

        if attempt_index >= max_repairs:
            break

        feedback = build_verifier_feedback(state, outcome, repair_attempt=attempt_index + 1)
        attempt["verifier_feedback"] = feedback
        try:
            payload = revise(feedback)
        except Exception as exc:  # noqa: BLE001 - preserve bounded failure evidence.
            return repair_result(
                attempts,
                selected=None,
                initial_safe=initial_safe,
                max_repairs=max_repairs,
                stopped_reason="revision_generation_failed",
                generation_error=str(exc)[:500],
            )

    return repair_result(
        attempts,
        selected=None,
        initial_safe=initial_safe,
        max_repairs=max_repairs,
        stopped_reason="repair_limit_reached",
    )


def evaluate_payload(
    state: EcosystemState,
    payload: dict[str, Any],
    *,
    source: str,
    strategy: str,
) -> dict[str, Any]:
    raw_action = safe_action_payload(payload)
    try:
        action = EcosystemAction.from_dict(payload)
    except (TypeError, ValueError) as exc:
        return {
            "source": source,
            "strategy": strategy,
            "action": raw_action,
            "accepted": False,
            "product_safe": False,
            "parse_error": str(exc),
            "violations": [f"model response could not be parsed: {exc}"],
            "product_violations": [],
            "warnings": [],
            "reward": None,
            "final_state": None,
        }

    outcome = evaluate_action(state, action)
    outcome.update({"source": source, "strategy": strategy, "parse_error": None})
    outcome["product_safe"] = outcome_preserves_loop(outcome)
    outcome["product_violations"] = (
        [] if outcome["product_safe"] or outcome.get("accepted") is not True
        else [_SIMULATED_COLLAPSE_VIOLATION]
    )
    return outcome


def outcome_preserves_loop(outcome: Any) -> bool:
    return bool(
        isinstance(outcome, dict)
        and outcome.get("accepted") is True
        and isinstance(outcome.get("final_state"), dict)
        and outcome["final_state"].get("collapsed") is not True
    )


def repair_result(
    attempts: list[dict[str, Any]],
    *,
    selected: dict[str, Any] | None,
    initial_safe: bool,
    max_repairs: int,
    stopped_reason: str,
    generation_error: str | None = None,
) -> dict[str, Any]:
    repair_count = max(0, len(attempts) - 1)
    final_safe = outcome_preserves_loop(selected)
    result = {
        "method": "bounded_verifier_feedback_repair",
        "weight_updates": False,
        "claim": "inference-time repair; no training or model weight updates",
        "max_repairs": max_repairs,
        "attempt_count": len(attempts),
        "repair_count": repair_count,
        "initial_safe": initial_safe,
        "final_safe": final_safe,
        "repaired_by_model": bool(not initial_safe and final_safe and repair_count > 0),
        "selected": selected,
        "attempts": attempts,
        "stopped_reason": stopped_reason,
    }
    if generation_error:
        result["generation_error"] = generation_error
    return result


def safe_action_payload(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        return {}
    return {key: value[key] for key in _ACTION_KEYS if key in value}


def expand_emergency_scenarios(
    base_scenarios: list[dict[str, Any]] | tuple[dict[str, Any], ...],
    *,
    variants_per_scenario: int = 4,
) -> list[dict[str, Any]]:
    if variants_per_scenario < 1 or variants_per_scenario > len(_VARIANTS):
        raise ValueError(f"variants_per_scenario must be between 1 and {len(_VARIANTS)}")

    expanded: list[dict[str, Any]] = []
    for base_index, base in enumerate(base_scenarios):
        base_name = str(base.get("name") or f"scenario {base_index + 1}")
        base_state = deepcopy(base.get("state") or {})
        for variant_index, profile in enumerate(_VARIANTS[:variants_per_scenario]):
            state = apply_variant(base_state, profile)
            expanded.append(
                {
                    "name": f"{base_name} / {profile['label']}",
                    "base_name": base_name,
                    "base_index": base_index,
                    "variant": profile["label"],
                    "variant_index": variant_index,
                    "state": state,
                }
            )
    return expanded


def apply_variant(base_state: dict[str, Any], profile: dict[str, Any]) -> dict[str, Any]:
    state = deepcopy(base_state)
    aquatic_factor = float(profile.get("aquatic_factor", 1.0))
    state["ammonia_mg_l"] = max(
        0.0,
        float(state.get("ammonia_mg_l", 0.35)) + float(profile.get("ammonia_delta", 0.0)),
    )
    state["dissolved_oxygen_mg_l"] = max(
        0.0,
        float(state.get("dissolved_oxygen_mg_l", 6.8)) + float(profile.get("oxygen_delta", 0.0)),
    )
    state["fish_biomass_kg"] = max(
        0.0,
        float(state.get("fish_biomass_kg", 12.0)) * aquatic_factor,
    )
    state["prawn_biomass_kg"] = max(
        0.0,
        float(state.get("prawn_biomass_kg", 2.5)) * aquatic_factor,
    )
    state["duckweed_kg"] = max(
        0.5,
        float(state.get("duckweed_kg", 3.0)) * float(profile.get("duckweed_factor", 1.0)),
    )
    state["plant_biomass_kg"] = max(
        0.0,
        float(state.get("plant_biomass_kg", 5.0)) * float(profile.get("plant_factor", 1.0)),
    )
    state["temperature_c"] = float(state.get("temperature_c", 26.0)) + float(
        profile.get("temperature_delta", 0.0)
    )
    state["stress_days"] = max(
        0,
        int(state.get("stress_days", 0)) + int(profile.get("stress_delta", 0)),
    )
    return EcosystemState.from_dict(state).to_dict()


def summarize_repair_evaluation(records: list[dict[str, Any]]) -> dict[str, Any]:
    scenario_count = len(records)
    if scenario_count == 0:
        return empty_repair_summary()

    requests = [
        request
        for record in records
        for request in record.get("model_requests") or []
        if isinstance(request, dict)
    ]
    latencies = [numeric(request.get("latency_ms")) for request in requests]
    latencies = [value for value in latencies if value is not None and value >= 0]
    prompt_tokens = sum(integer(request.get("prompt_tokens")) for request in requests)
    completion_tokens = sum(integer(request.get("completion_tokens")) for request in requests)
    total_tokens = sum(integer(request.get("total_tokens")) for request in requests)
    latency_seconds = sum(latencies) / 1000.0
    reward_deltas = numeric_record_values(records, "reward_delta_vs_naive")

    return {
        "scenario_count": scenario_count,
        "first_answer_safe_count": count_true(records, "first_answer_safe"),
        "first_answer_safe_rate": rate(records, "first_answer_safe"),
        "repair_path_safe_count": count_true(records, "repair_path_safe"),
        "repair_path_safe_rate": rate(records, "repair_path_safe"),
        "best_of_n_safe_count": count_true(records, "best_of_n_safe"),
        "best_of_n_safe_rate": rate(records, "best_of_n_safe"),
        "combined_model_safe_count": count_true(records, "combined_model_safe"),
        "combined_model_safe_rate": rate(records, "combined_model_safe"),
        "final_system_safe_count": count_true(records, "final_system_safe"),
        "final_system_safe_rate": rate(records, "final_system_safe"),
        "repair_rescue_count": count_true(records, "repair_rescued_first_rejection"),
        "deterministic_fallback_count": count_true(records, "fallback_used"),
        "deterministic_fallback_rate": rate(records, "fallback_used"),
        "unsafe_control_rejection_rate": rate(records, "unsafe_control_rejected"),
        "protected_aquatic_biomass_kg": round(
            sum(float(record.get("protected_aquatic_biomass_kg") or 0.0) for record in records),
            4,
        ),
        "mean_reward_delta_vs_naive": (
            round(mean(reward_deltas), 4) if reward_deltas else None
        ),
        "model_request_count": len(requests),
        "token_usage": {
            "prompt_tokens": prompt_tokens,
            "completion_tokens": completion_tokens,
            "total_tokens": total_tokens,
        },
        "request_latency_ms": {
            "sample_count": len(latencies),
            "p50": percentile(latencies, 0.50),
            "p95": percentile(latencies, 0.95),
        },
        "observed_completion_tokens_per_second": (
            round(completion_tokens / latency_seconds, 3)
            if completion_tokens > 0 and latency_seconds > 0
            else None
        ),
    }


def count_true(records: list[dict[str, Any]], key: str) -> int:
    return sum(1 for record in records if record.get(key) is True)


def rate(records: list[dict[str, Any]], key: str) -> float:
    return round(count_true(records, key) / len(records), 4) if records else 0.0


def numeric_record_values(records: list[dict[str, Any]], key: str) -> list[float]:
    values = [numeric(record.get(key)) for record in records]
    return [value for value in values if value is not None]


def numeric(value: Any) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return float(value)


def integer(value: Any) -> int:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return 0
    return max(0, int(value))


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


def empty_repair_summary() -> dict[str, Any]:
    return {
        "scenario_count": 0,
        "first_answer_safe_count": 0,
        "first_answer_safe_rate": 0.0,
        "repair_path_safe_count": 0,
        "repair_path_safe_rate": 0.0,
        "best_of_n_safe_count": 0,
        "best_of_n_safe_rate": 0.0,
        "combined_model_safe_count": 0,
        "combined_model_safe_rate": 0.0,
        "final_system_safe_count": 0,
        "final_system_safe_rate": 0.0,
        "repair_rescue_count": 0,
        "deterministic_fallback_count": 0,
        "deterministic_fallback_rate": 0.0,
        "unsafe_control_rejection_rate": 0.0,
        "protected_aquatic_biomass_kg": 0.0,
        "mean_reward_delta_vs_naive": None,
        "model_request_count": 0,
        "token_usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
        "request_latency_ms": {"sample_count": 0, "p50": None, "p95": None},
        "observed_completion_tokens_per_second": None,
    }
