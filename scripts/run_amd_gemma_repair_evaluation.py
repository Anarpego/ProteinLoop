"""Run a 20-scenario AMD Gemma verifier-feedback repair evaluation."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "sim"))

from proteinloop_sim.gemma_repair import (  # noqa: E402
    expand_emergency_scenarios,
    run_verifier_feedback_repair,
    summarize_repair_evaluation,
)
from proteinloop_sim.gemma_search import evaluate_candidates  # noqa: E402
from proteinloop_sim.product_evaluation import (  # noqa: E402
    ensure_safe_selection,
    numeric_reward,
    reward_delta,
)
from proteinloop_sim.state import EcosystemState  # noqa: E402
from scripts.run_amd_gemma_policy_search import (  # noqa: E402
    STRATEGIES,
    candidate_request,
    unsafe_control_candidate,
)
from scripts.run_amd_gemma_product_evaluation import SCENARIOS  # noqa: E402
from scripts.validate_gemma_endpoint import (  # noqa: E402
    DEFAULT_MODEL,
    normalize_endpoint,
    parse_chat_action,
    post_json,
    write_evidence,
)


DEFAULT_OUTPUT = ROOT / "submission" / "amd-gemma-repair-evaluation.json"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    endpoint = normalize_endpoint(args.endpoint or os.environ.get("GEMMA_ENDPOINT"))
    model = args.model or os.environ.get("GEMMA_MODEL") or DEFAULT_MODEL
    api_key = args.api_key if args.api_key is not None else os.environ.get("GEMMA_API_KEY")
    scenarios = expand_emergency_scenarios(
        SCENARIOS,
        variants_per_scenario=args.variants_per_scenario,
    )
    records: list[dict[str, Any]] = []
    generation_errors: list[dict[str, Any]] = []

    for scenario_index, scenario in enumerate(scenarios):
        state = EcosystemState.from_dict(scenario["state"])
        record, errors = evaluate_scenario(
            endpoint=endpoint,
            model=model,
            api_key=api_key,
            timeout=args.timeout,
            scenario_index=scenario_index,
            scenario=scenario,
            state=state,
            independent_candidates=args.independent_candidates,
            max_repairs=args.max_repairs,
        )
        records.append(record)
        generation_errors.extend(errors)
        print(
            f"[{scenario_index + 1:02d}/{len(scenarios)}] {scenario['name']}: "
            f"first={record['first_answer_safe']} repair={record['repair_path_safe']} "
            f"best_of_n={record['best_of_n_safe']} model={record['combined_model_safe']} "
            f"fallback={record['fallback_used']}"
        )

    summary = summarize_repair_evaluation(records)
    checks = {
        "all_scenarios_evaluated": summary["scenario_count"] == 20,
        "repair_attempts_bounded": all(
            int(record["repair_trace"]["repair_count"]) <= args.max_repairs
            for record in records
        ),
        "unsafe_controls_rejected": summary["unsafe_control_rejection_rate"] == 1.0,
        "safe_plan_selected_every_time": summary["final_system_safe_rate"] == 1.0,
        "combined_model_not_worse_than_first": (
            summary["combined_model_safe_rate"] >= summary["first_answer_safe_rate"]
        ),
        "fallback_usage_disclosed": all(
            isinstance(record.get("fallback_used"), bool) for record in records
        ),
        "token_usage_reported": summary["token_usage"]["total_tokens"] > 0,
        "no_weight_updates": all(
            record["repair_trace"]["weight_updates"] is False for record in records
        ),
    }
    evidence = {
        "schema_version": 1,
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "provider": "amd_hackathon_notebook",
        "endpoint": endpoint,
        "model": model,
        "method": "twenty_scenario_verifier_feedback_repair",
        "claim": "inference-time repair and search; no training or model weight updates",
        "scenario_count": len(scenarios),
        "variants_per_base_scenario": args.variants_per_scenario,
        "independent_candidates_per_scenario": args.independent_candidates,
        "max_repairs": args.max_repairs,
        "generation_errors": generation_errors,
        "summary": summary,
        "scenarios": records,
        "checks": checks,
    }

    failed = [name for name, passed in checks.items() if not passed]
    if failed:
        print(f"AMD Gemma repair evaluation failed: {', '.join(failed)}", file=sys.stderr)
        return 1

    output = Path(args.evidence_file)
    write_evidence(output, evidence)
    print(f"wrote AMD Gemma repair evaluation: {output}")
    print(
        "first-safe="
        f"{summary['first_answer_safe_rate']} "
        f"repair-safe={summary['repair_path_safe_rate']} "
        f"combined-model-safe={summary['combined_model_safe_rate']} "
        f"fallback-rate={summary['deterministic_fallback_rate']}"
    )
    return 0


def evaluate_scenario(
    *,
    endpoint: str,
    model: str,
    api_key: str | None,
    timeout: float,
    scenario_index: int,
    scenario: dict[str, Any],
    state: EcosystemState,
    independent_candidates: int,
    max_repairs: int,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    scenario_name = str(scenario["name"])
    state_payload = state.to_dict()
    requests: list[dict[str, Any]] = []
    errors: list[dict[str, Any]] = []
    initial_action = failed_generation_payload("initial model request failed")

    try:
        initial_action, metric = request_action(
            endpoint,
            candidate_request(
                model,
                STRATEGIES[0],
                seed=8100 + scenario_index * 100,
                state=state_payload,
            ),
            api_key,
            timeout,
            phase="initial",
            scenario=scenario_name,
            attempt=0,
        )
        requests.append(metric)
    except Exception as exc:  # noqa: BLE001 - preserve partial evidence and continue repairs.
        errors.append(generation_error(scenario_name, "initial", 0, exc))

    initial_action["_source"] = "amd_hosted_gemma"
    initial_action["_strategy"] = STRATEGIES[0]
    repair_call_index = 0

    def revise(feedback: dict[str, Any]) -> dict[str, Any]:
        nonlocal repair_call_index
        repair_call_index += 1
        action, metric = request_action(
            endpoint,
            repair_request(
                model,
                feedback,
                seed=8200 + scenario_index * 100 + repair_call_index,
            ),
            api_key,
            timeout,
            phase="repair",
            scenario=scenario_name,
            attempt=repair_call_index,
        )
        requests.append(metric)
        action["_source"] = "amd_hosted_gemma_repair"
        action["_strategy"] = f"verifier-feedback repair {repair_call_index}"
        return action

    repair_trace = run_verifier_feedback_repair(
        state,
        initial_action,
        revise,
        max_repairs=max_repairs,
    )
    if repair_trace.get("generation_error"):
        errors.append(
            {
                "scenario": scenario_name,
                "phase": "repair",
                "attempt": repair_call_index,
                "error": str(repair_trace["generation_error"])[:500],
            }
        )

    independent_actions: list[dict[str, Any]] = []
    for strategy_index, strategy in enumerate(STRATEGIES[1:independent_candidates], start=1):
        try:
            action, metric = request_action(
                endpoint,
                candidate_request(
                    model,
                    strategy,
                    seed=8300 + scenario_index * 100 + strategy_index,
                    state=state_payload,
                ),
                api_key,
                timeout,
                phase="best_of_n",
                scenario=scenario_name,
                attempt=strategy_index,
            )
            requests.append(metric)
            action["_source"] = "amd_hosted_gemma"
            action["_strategy"] = strategy
            independent_actions.append(action)
        except Exception as exc:  # noqa: BLE001 - retain other candidates.
            errors.append(generation_error(scenario_name, "best_of_n", strategy_index, exc))

    control = unsafe_control_candidate()
    best_of_n_search = evaluate_candidates(
        state,
        [control, initial_action, *independent_actions],
    )
    repair_actions = [
        outcome_candidate(attempt["outcome"])
        for attempt in repair_trace["attempts"]
        if isinstance(attempt.get("outcome"), dict)
    ]
    combined_search = evaluate_candidates(
        state,
        [control, *repair_actions, *independent_actions],
    )
    final_search = ensure_safe_selection(state, combined_search)

    first = repair_trace["attempts"][0]["outcome"]
    repair_selected = repair_trace.get("selected")
    best_selected = best_of_n_search.get("selected")
    model_selected = combined_search.get("selected")
    final_selected = final_search.get("selected")
    baseline = combined_search.get("baseline")
    aquatic_biomass = state.aquatic_biomass_kg
    final_safe = preserves_loop(final_selected)
    final_state = (
        final_selected.get("final_state") if isinstance(final_selected, dict) else None
    )
    preserved = bool(
        final_safe
        and isinstance(final_state, dict)
        and final_state.get("collapsed") is not True
    )

    return (
        {
            "name": scenario_name,
            "base_name": scenario["base_name"],
            "variant": scenario["variant"],
            "variant_index": scenario["variant_index"],
            "initial_state": state_payload,
            "aquatic_biomass_kg": round(aquatic_biomass, 4),
            "first_answer": first,
            "repair_trace": repair_trace,
            "best_of_n_search": best_of_n_search,
            "combined_model_search": combined_search,
            "final_selection": final_selected,
            "first_answer_safe": preserves_loop(first),
            "repair_path_safe": preserves_loop(repair_selected),
            "best_of_n_safe": preserves_loop(best_selected),
            "combined_model_safe": preserves_loop(model_selected),
            "final_system_safe": final_safe,
            "repair_rescued_first_rejection": bool(
                not preserves_loop(first) and preserves_loop(repair_selected)
            ),
            "fallback_used": final_search.get("fallback_used") is True,
            "unsafe_control_rejected": control_rejected(combined_search),
            "reward_delta_vs_naive": reward_delta(
                numeric_reward(final_selected),
                numeric_reward(baseline),
            ),
            "protected_aquatic_biomass_kg": round(aquatic_biomass, 4) if preserved else 0.0,
            "model_requests": requests,
            "generation_errors": errors,
        },
        errors,
    )


def repair_request(model: str, feedback: dict[str, Any], seed: int) -> dict[str, Any]:
    return {
        "model": model,
        "temperature": 0.2,
        "seed": seed,
        "chat_template_kwargs": {"enable_thinking": False},
        "response_format": {"type": "json_object"},
        "messages": [
            {
                "role": "system",
                "content": (
                    "You repair ProteinLoop recovery actions after deterministic verification. "
                    "Return only the revised action as one JSON object with numeric feed_kg, "
                    "aeration_hours, water_exchange_fraction, duckweed_harvest_kg, and a short "
                    "note. Obey every hard limit and directly correct every listed violation. "
                    "Do not return prose, markdown, hidden reasoning, or predicted measurements."
                ),
            },
            {
                "role": "user",
                "content": (
                    "Deterministic verifier feedback JSON: "
                    f"{json.dumps(feedback, sort_keys=True)}"
                ),
            },
        ],
    }


def request_action(
    endpoint: str,
    request_payload: dict[str, Any],
    api_key: str | None,
    timeout: float,
    *,
    phase: str,
    scenario: str,
    attempt: int,
) -> tuple[dict[str, Any], dict[str, Any]]:
    started = time.perf_counter()
    payload = post_json(
        f"{endpoint}/v1/chat/completions",
        request_payload,
        api_key,
        timeout,
    )
    latency_ms = round((time.perf_counter() - started) * 1000, 3)
    return (
        parse_chat_action(payload),
        extract_request_metrics(
            payload,
            latency_ms=latency_ms,
            phase=phase,
            scenario=scenario,
            attempt=attempt,
        ),
    )


def extract_request_metrics(
    payload: dict[str, Any],
    *,
    latency_ms: float,
    phase: str,
    scenario: str,
    attempt: int,
) -> dict[str, Any]:
    usage = payload.get("usage") if isinstance(payload.get("usage"), dict) else {}
    return {
        "phase": phase,
        "scenario": scenario,
        "attempt": int(attempt),
        "latency_ms": round(float(latency_ms), 3),
        "prompt_tokens": safe_non_negative_int(usage.get("prompt_tokens")),
        "completion_tokens": safe_non_negative_int(usage.get("completion_tokens")),
        "total_tokens": safe_non_negative_int(usage.get("total_tokens")),
    }


def safe_non_negative_int(value: Any) -> int:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return 0
    return max(0, int(value))


def outcome_candidate(outcome: dict[str, Any]) -> dict[str, Any]:
    action = dict(outcome.get("action") or {})
    action["_source"] = outcome.get("source", "amd_hosted_gemma_repair")
    action["_strategy"] = outcome.get("strategy", "verifier-feedback repair")
    return action


def failed_generation_payload(note: str) -> dict[str, Any]:
    return {
        "feed_kg": "generation_failed",
        "aeration_hours": 0,
        "water_exchange_fraction": 0,
        "duckweed_harvest_kg": 0,
        "note": note,
    }


def generation_error(scenario: str, phase: str, attempt: int, exc: Exception) -> dict[str, Any]:
    return {
        "scenario": scenario,
        "phase": phase,
        "attempt": int(attempt),
        "error": str(exc)[:500],
    }


def accepted(value: Any) -> bool:
    return isinstance(value, dict) and value.get("accepted") is True


def preserves_loop(value: Any) -> bool:
    return bool(
        accepted(value)
        and isinstance(value.get("final_state"), dict)
        and value["final_state"].get("collapsed") is not True
    )


def control_rejected(search: dict[str, Any]) -> bool:
    return any(
        candidate.get("source") == "control_unsafe" and candidate.get("accepted") is False
        for candidate in search.get("candidates") or []
        if isinstance(candidate, dict)
    )


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--endpoint", default="http://127.0.0.1:8001")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--api-key")
    parser.add_argument("--independent-candidates", type=int, default=6, choices=range(2, 7))
    parser.add_argument("--max-repairs", type=int, default=3, choices=range(0, 4))
    parser.add_argument("--variants-per-scenario", type=int, default=4, choices=range(1, 5))
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument("--evidence-file", default=str(DEFAULT_OUTPUT))
    return parser.parse_args(argv)


if __name__ == "__main__":
    raise SystemExit(main())
