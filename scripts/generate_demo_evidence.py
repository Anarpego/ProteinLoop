"""Generate current demo evidence for the hackathon submission packet."""

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "sim"))

from proteinloop_sim.forecast import forecast_anomaly  # noqa: E402
from proteinloop_sim.policies import naive_policy, run_policy, safety_policy  # noqa: E402
from proteinloop_sim.rlvr import evaluate_policies, train_policy  # noqa: E402
from proteinloop_sim.simulator import EcosystemSimulator  # noqa: E402


OUT_JSON = ROOT / "submission" / "demo-evidence.json"
OUT_MD = ROOT / "submission" / "demo-evidence.md"


def main() -> int:
    naive = run_policy(naive_policy, days=8, spike_day=1, validate=False)
    safety = run_policy(safety_policy, days=8, spike_day=1, validate=True)
    rlvr = evaluate_policies()
    training = train_policy()

    spike_sim = EcosystemSimulator()
    spike_sim.apply_ammonia_spike()
    forecast = forecast_anomaly(spike_sim.state)

    evidence = {
        "collapse_vs_recovery": {
            "days": 8,
            "spike_day": 1,
            "naive": {
                "collapsed": naive.state.collapsed,
                "day": naive.state.day,
                "reward": naive.verifier.reward(naive.state),
                "ammonia_mg_l": naive.state.ammonia_mg_l,
                "oxygen_mg_l": naive.state.dissolved_oxygen_mg_l,
            },
            "safety": {
                "collapsed": safety.state.collapsed,
                "day": safety.state.day,
                "reward": safety.verifier.reward(safety.state),
                "ammonia_mg_l": safety.state.ammonia_mg_l,
                "oxygen_mg_l": safety.state.dissolved_oxygen_mg_l,
            },
        },
        "rlvr": {
            "baseline_policy": rlvr.baseline_policy,
            "candidate_policy": rlvr.candidate_policy,
            "scenario_count": len(rlvr.scenarios),
            "average_reward_delta": rlvr.average_reward_delta,
            "recovered_scenarios": rlvr.recovered_scenarios,
            "collapse_avoidance_rate": rlvr.collapse_avoidance_rate,
        },
        "rlvr_training": {
            "method": training.method,
            "baseline_policy": training.baseline_policy,
            "best_policy": training.best_policy.to_dict(),
            "iteration_count": training.iteration_count,
            "initial_reward": training.initial_reward,
            "best_reward": training.best_reward,
            "improvement": training.improvement,
            "iterations": [iteration.to_dict() for iteration in training.iterations],
        },
        "anomaly_forecast_after_spike": forecast.to_dict(),
    }

    OUT_JSON.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    OUT_MD.write_text(markdown(evidence), encoding="utf-8")
    print(f"wrote {OUT_JSON.relative_to(ROOT)}")
    print(f"wrote {OUT_MD.relative_to(ROOT)}")
    return 0


def markdown(evidence: dict[str, object]) -> str:
    cvr = evidence["collapse_vs_recovery"]
    naive = cvr["naive"]
    safety = cvr["safety"]
    rlvr = evidence["rlvr"]
    training = evidence["rlvr_training"]
    forecast = evidence["anomaly_forecast_after_spike"]

    return "\n".join(
        [
            "# ProteinLoop Demo Evidence",
            "",
            "Generated from executable simulator code.",
            "",
            "## Collapse Versus Recovery",
            "",
            f"- Horizon: {cvr['days']} days; ammonia spike day: {cvr['spike_day']}.",
            f"- Naive policy collapsed: {naive['collapsed']}; reward: {naive['reward']}.",
            f"- Safety policy collapsed: {safety['collapsed']}; reward: {safety['reward']}.",
            f"- Safety final ammonia: {safety['ammonia_mg_l']:.3f} mg/L; oxygen: {safety['oxygen_mg_l']:.3f} mg/L.",
            "",
            "## RLVR Summary",
            "",
            f"- Policy comparison: {rlvr['baseline_policy']} -> {rlvr['candidate_policy']}.",
            f"- Scenarios: {rlvr['scenario_count']}.",
            f"- Average reward delta: {rlvr['average_reward_delta']}.",
            f"- Recovered scenarios: {rlvr['recovered_scenarios']}.",
            f"- Collapse avoidance rate: {rlvr['collapse_avoidance_rate']}.",
            "",
            "## RLVR Policy Search",
            "",
            f"- Method: {training['method']}.",
            f"- Best policy: {training['best_policy']['name']}.",
            f"- Iterations: {training['iteration_count']}.",
            f"- Initial reward: {training['initial_reward']}.",
            f"- Best reward: {training['best_reward']}.",
            f"- Improvement: {training['improvement']}.",
            "",
            "## Forecast After Ammonia Spike",
            "",
            f"- Risk level: {forecast['risk_level']}.",
            f"- First critical day: {forecast['first_critical_day']}.",
            f"- Recommendation: {str(forecast['recommendation']).rstrip('.')}.",
            "",
        ]
    )


if __name__ == "__main__":
    raise SystemExit(main())
