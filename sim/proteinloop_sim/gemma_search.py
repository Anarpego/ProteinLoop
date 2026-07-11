"""Verifier-guided ranking for model-proposed ProteinLoop actions."""

from __future__ import annotations

from typing import Any

from .actions import EcosystemAction
from .policies import naive_policy
from .simulator import EcosystemSimulator
from .state import EcosystemState
from .verifier import SafetyVerifier


def evaluate_candidates(
    initial_state: EcosystemState,
    candidates: list[dict[str, Any]],
) -> dict[str, Any]:
    verifier = SafetyVerifier()
    baseline = evaluate_action(initial_state, naive_policy(initial_state), verifier)
    outcomes: list[dict[str, Any]] = []

    for index, payload in enumerate(candidates):
        source = str(payload.get("_source", "model")) if isinstance(payload, dict) else "model"
        strategy = str(payload.get("_strategy", "")) if isinstance(payload, dict) else ""
        try:
            action = EcosystemAction.from_dict(payload)
        except (TypeError, ValueError) as exc:
            outcomes.append(
                {
                    "index": index,
                    "source": source,
                    "strategy": strategy,
                    "accepted": False,
                    "parse_error": str(exc),
                    "violations": [],
                    "reward": None,
                }
            )
            continue

        outcome = evaluate_action(initial_state, action, verifier)
        outcome.update({"index": index, "source": source, "strategy": strategy})
        outcomes.append(outcome)

    accepted = [item for item in outcomes if item.get("accepted") is True]
    selected = max(accepted, key=lambda item: float(item["reward"])) if accepted else None
    selected_reward = float(selected["reward"]) if selected else None
    baseline_reward = float(baseline["reward"]) if baseline.get("reward") is not None else None

    return {
        "method": "verifier_guided_best_of_n",
        "weight_updates": False,
        "claim": "inference-time policy search; no RL training or fine-tuning",
        "verifier": "proteinloop_sim.verifier.SafetyVerifier",
        "reward_function": "proteinloop_sim.verifier.SafetyVerifier.reward",
        "initial_state": initial_state.to_dict(),
        "baseline": baseline,
        "candidates": outcomes,
        "candidate_count": len(outcomes),
        "safe_count": len(accepted),
        "rejected_count": sum(
            1 for item in outcomes if not item.get("accepted") and not item.get("parse_error")
        ),
        "parse_error_count": sum(1 for item in outcomes if item.get("parse_error")),
        "selected": selected,
        "reward_delta_vs_naive": (
            round(selected_reward - baseline_reward, 4)
            if selected_reward is not None and baseline_reward is not None
            else None
        ),
    }


def evaluate_action(
    initial_state: EcosystemState,
    action: EcosystemAction,
    verifier: SafetyVerifier | None = None,
) -> dict[str, Any]:
    verifier = verifier or SafetyVerifier()
    verification = verifier.validate_action(initial_state, action)
    if not verification.ok:
        return {
            "action": action.to_dict(),
            "accepted": False,
            "violations": list(verification.violations),
            "warnings": list(verification.warnings),
            "reward": None,
            "final_state": None,
        }

    simulator = EcosystemSimulator(state=initial_state, verifier=verifier)
    result = simulator.step(action, validate=True)
    return {
        "action": action.to_dict(),
        "accepted": True,
        "violations": [],
        "warnings": list(result.verification.warnings),
        "reward": result.reward,
        "final_state": result.state.to_dict(),
    }
