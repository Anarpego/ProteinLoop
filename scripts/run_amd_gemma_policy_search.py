"""Generate Gemma recovery candidates on AMD and rank them with simulator reward."""

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

from proteinloop_sim.gemma_search import evaluate_candidates  # noqa: E402
from proteinloop_sim.state import EcosystemState  # noqa: E402
from scripts.validate_gemma_endpoint import (  # noqa: E402
    DEFAULT_MODEL,
    PROMPT_STATE,
    normalize_endpoint,
    parse_chat_action,
    post_json,
    write_evidence,
)


DEFAULT_OUTPUT = ROOT / "submission" / "amd-gemma-policy-search.json"
STRATEGIES = (
    "oxygen-first emergency recovery",
    "minimal-water recovery",
    "protein-survival maximization",
    "low-energy recovery",
    "balanced water and feed recovery",
    "conservative zero-mortality recovery",
)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    endpoint = normalize_endpoint(args.endpoint or os.environ.get("GEMMA_ENDPOINT"))
    model = args.model or os.environ.get("GEMMA_MODEL") or DEFAULT_MODEL
    api_key = args.api_key if args.api_key is not None else os.environ.get("GEMMA_API_KEY")
    candidates: list[dict[str, Any]] = [unsafe_control_candidate()]
    generation_errors: list[dict[str, Any]] = []
    latencies: list[float] = []

    for index, strategy in enumerate(STRATEGIES[: args.candidates]):
        started = time.perf_counter()
        try:
            payload = post_json(
                f"{endpoint}/v1/chat/completions",
                candidate_request(model, strategy, seed=4100 + index),
                api_key,
                args.timeout,
            )
            action = parse_chat_action(payload)
            action["_source"] = "amd_hosted_gemma"
            action["_strategy"] = strategy
            candidates.append(action)
        except Exception as exc:  # noqa: BLE001 - preserve partial search evidence.
            generation_errors.append({"strategy": strategy, "error": str(exc)[:500]})
        latencies.append(round((time.perf_counter() - started) * 1000, 3))

    model_candidates = [item for item in candidates if item.get("_source") == "amd_hosted_gemma"]
    if not model_candidates:
        print("no Gemma candidates were generated", file=sys.stderr)
        for error in generation_errors:
            print(f"{error['strategy']}: {error['error']}", file=sys.stderr)
        return 1

    search = evaluate_candidates(EcosystemState.from_dict(PROMPT_STATE), candidates)
    selected = search.get("selected")
    evidence = {
        "schema_version": 1,
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "provider": "amd_hackathon_notebook",
        "endpoint": endpoint,
        "model": model,
        "requested_model_candidates": args.candidates,
        "generated_model_candidates": len(model_candidates),
        "generation_errors": generation_errors,
        "generation_latency_ms": latencies,
        "search": search,
        "checks": {
            "amd_gemma_generated_candidates": bool(model_candidates),
            "unsafe_control_rejected": any(
                item.get("source") == "control_unsafe" and not item.get("accepted")
                for item in search["candidates"]
            ),
            "safe_candidate_selected": bool(selected and selected.get("accepted")),
            "positive_reward_delta_vs_naive": bool(
                search.get("reward_delta_vs_naive") is not None
                and search["reward_delta_vs_naive"] > 0
            ),
            "no_weight_update_claim_is_explicit": search["weight_updates"] is False,
        },
    }
    failed = [name for name, passed in evidence["checks"].items() if not passed]
    if failed:
        print(f"policy search evidence failed: {', '.join(failed)}", file=sys.stderr)
        return 1

    output = Path(args.evidence_file)
    write_evidence(output, evidence)
    print(f"wrote AMD Gemma policy search: {output}")
    print(f"selected reward delta vs naive: {search['reward_delta_vs_naive']}")
    print(f"safe={search['safe_count']} rejected={search['rejected_count']}")
    return 0


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--endpoint", default="http://127.0.0.1:8001")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--api-key")
    parser.add_argument("--candidates", type=int, default=len(STRATEGIES), choices=range(2, 7))
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument("--evidence-file", default=str(DEFAULT_OUTPUT))
    return parser.parse_args(argv)


def candidate_request(
    model: str,
    strategy: str,
    seed: int,
    state: dict[str, Any] | None = None,
) -> dict[str, Any]:
    prompt_state = state or PROMPT_STATE
    return {
        "model": model,
        "temperature": 0.75,
        "seed": seed,
        "chat_template_kwargs": {"enable_thinking": False},
        "response_format": {"type": "json_object"},
        "messages": [
            {
                "role": "system",
                "content": (
                    "Return exactly one JSON object with numeric feed_kg, aeration_hours, "
                    "water_exchange_fraction, duckweed_harvest_kg, and a short note. "
                    "Do not include reasoning or markdown. The deterministic simulator will "
                    "independently reject unsafe plans and rank safe plans by ecosystem reward."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Strategy objective: {strategy}. Current state: "
                    f"{json.dumps(prompt_state, sort_keys=True)}. Propose one bounded daily action."
                ),
            },
        ],
    }


def unsafe_control_candidate() -> dict[str, Any]:
    return {
        "_source": "control_unsafe",
        "_strategy": "deliberate verifier control",
        "feed_kg": 2.0,
        "aeration_hours": 30.0,
        "water_exchange_fraction": 0.60,
        "duckweed_harvest_kg": 12.0,
        "note": "deliberately unsafe control; must be rejected before mutation",
    }


if __name__ == "__main__":
    raise SystemExit(main())
