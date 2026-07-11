"""Evaluate AMD-hosted Gemma product outcomes across closed-loop emergencies."""

from __future__ import annotations

import argparse
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "sim"))

from proteinloop_sim.gemma_search import evaluate_candidates  # noqa: E402
from proteinloop_sim.product_evaluation import (  # noqa: E402
    build_scenario_record,
    ensure_safe_selection,
    summarize_product_evaluation,
)
from proteinloop_sim.state import EcosystemState  # noqa: E402
from scripts.run_amd_gemma_policy_search import (  # noqa: E402
    STRATEGIES,
    candidate_request,
    unsafe_control_candidate,
)
from scripts.validate_gemma_endpoint import (  # noqa: E402
    DEFAULT_MODEL,
    normalize_endpoint,
    parse_chat_action,
    post_json,
    write_evidence,
)


DEFAULT_OUTPUT = ROOT / "submission" / "amd-gemma-product-evaluation.json"

SCENARIOS: tuple[dict[str, Any], ...] = (
    {
        "name": "ammonia surge",
        "state": {
            "day": 3,
            "ammonia_mg_l": 2.4,
            "dissolved_oxygen_mg_l": 4.8,
            "fish_biomass_kg": 18.0,
            "prawn_biomass_kg": 5.4,
            "duckweed_kg": 12.0,
            "plant_biomass_kg": 21.0,
            "stress_days": 1,
        },
    },
    {
        "name": "oxygen crash",
        "state": {
            "day": 7,
            "ammonia_mg_l": 1.1,
            "dissolved_oxygen_mg_l": 3.2,
            "fish_biomass_kg": 14.0,
            "prawn_biomass_kg": 3.2,
            "duckweed_kg": 4.0,
            "plant_biomass_kg": 8.0,
            "stress_days": 2,
        },
    },
    {
        "name": "critical combined water emergency",
        "state": {
            "day": 11,
            "ammonia_mg_l": 3.4,
            "dissolved_oxygen_mg_l": 3.6,
            "fish_biomass_kg": 16.0,
            "prawn_biomass_kg": 4.0,
            "duckweed_kg": 6.0,
            "plant_biomass_kg": 12.0,
            "stress_days": 2,
        },
    },
    {
        "name": "feed reserve constraint",
        "state": {
            "day": 15,
            "ammonia_mg_l": 1.8,
            "dissolved_oxygen_mg_l": 5.1,
            "fish_biomass_kg": 12.0,
            "prawn_biomass_kg": 2.5,
            "duckweed_kg": 0.8,
            "plant_biomass_kg": 7.0,
            "stress_days": 1,
        },
    },
    {
        "name": "high biomass recovery",
        "state": {
            "day": 21,
            "ammonia_mg_l": 2.8,
            "dissolved_oxygen_mg_l": 4.0,
            "fish_biomass_kg": 22.0,
            "prawn_biomass_kg": 6.0,
            "duckweed_kg": 10.0,
            "plant_biomass_kg": 24.0,
            "stress_days": 1,
        },
    },
)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    endpoint = normalize_endpoint(args.endpoint or os.environ.get("GEMMA_ENDPOINT"))
    model = args.model or os.environ.get("GEMMA_MODEL") or DEFAULT_MODEL
    api_key = args.api_key if args.api_key is not None else os.environ.get("GEMMA_API_KEY")
    records: list[dict[str, Any]] = []
    generation_errors: list[dict[str, Any]] = []

    for scenario_index, scenario in enumerate(SCENARIOS):
        state = EcosystemState.from_dict(scenario["state"])
        state_payload = state.to_dict()
        candidates: list[dict[str, Any]] = [unsafe_control_candidate()]
        latencies: list[float] = []

        for strategy_index, strategy in enumerate(STRATEGIES[: args.candidates]):
            started = time.perf_counter()
            try:
                payload = post_json(
                    f"{endpoint}/v1/chat/completions",
                    candidate_request(
                        model,
                        strategy,
                        seed=7100 + scenario_index * 100 + strategy_index,
                        state=state_payload,
                    ),
                    api_key,
                    args.timeout,
                )
                action = parse_chat_action(payload)
                action["_source"] = "amd_hosted_gemma"
                action["_strategy"] = strategy
                candidates.append(action)
            except Exception as exc:  # noqa: BLE001 - preserve partial evaluation evidence.
                generation_errors.append(
                    {
                        "scenario": scenario["name"],
                        "strategy": strategy,
                        "error": str(exc)[:500],
                    }
                )
            latencies.append(round((time.perf_counter() - started) * 1000, 3))

        search = ensure_safe_selection(state, evaluate_candidates(state, candidates))
        records.append(
            build_scenario_record(scenario["name"], state_payload, search, latencies)
        )
        print(
            f"{scenario['name']}: safe={search['safe_count']} "
            f"rejected={search['rejected_count']} "
            f"delta_naive={search['reward_delta_vs_naive']} "
            f"fallback={search['fallback_used']}"
        )

    summary = summarize_product_evaluation(records)
    checks = {
        "all_scenarios_evaluated": summary["scenario_count"] == len(SCENARIOS),
        "unsafe_controls_rejected": summary["unsafe_control_rejection_rate"] == 1.0,
        "safe_plan_selected_every_time": summary["selected_plan_safe_rate"] == 1.0,
        "search_not_worse_than_first_on_safety": summary["safe_rate_lift"] >= 0.0,
        "no_weight_updates": all(record["weight_updates"] is False for record in records),
    }
    evidence = {
        "schema_version": 1,
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "provider": "amd_hackathon_notebook",
        "model": model,
        "method": "multi_scenario_verifier_guided_best_of_n",
        "claim": "product outcome evaluation; inference only; no model weight updates",
        "scenario_count": len(SCENARIOS),
        "candidates_per_scenario": args.candidates,
        "generation_errors": generation_errors,
        "summary": summary,
        "scenarios": records,
        "checks": checks,
    }

    failed = [name for name, passed in checks.items() if not passed]
    if failed:
        print(f"AMD Gemma product evaluation failed: {', '.join(failed)}", file=sys.stderr)
        return 1

    output = Path(args.evidence_file)
    write_evidence(output, evidence)
    print(f"wrote AMD Gemma product evaluation: {output}")
    print(
        "safe-rate lift="
        f"{summary['safe_rate_lift']} "
        f"rescues={summary['search_rescue_count']} "
        f"protected_biomass={summary['protected_aquatic_biomass_kg']} kg"
    )
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--endpoint", default="http://127.0.0.1:8001")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--api-key")
    parser.add_argument("--candidates", type=int, default=4, choices=range(3, 7))
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument("--evidence-file", default=str(DEFAULT_OUTPUT))
    return parser.parse_args(argv)


if __name__ == "__main__":
    raise SystemExit(main())
