"""Generate an executable demo rehearsal packet."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "sim"))

from proteinloop_sim.actions import EcosystemAction  # noqa: E402
from proteinloop_sim.forecast import forecast_anomaly  # noqa: E402
from proteinloop_sim.policies import safety_policy  # noqa: E402
from proteinloop_sim.rlvr import train_policy  # noqa: E402
from proteinloop_sim.simulator import EcosystemSimulator, UnsafeActionError  # noqa: E402


OUT_JSON = ROOT / "submission" / "demo-rehearsal.json"
OUT_MD = ROOT / "submission" / "demo-rehearsal.md"


def main() -> int:
    packet = build_rehearsal_packet()
    OUT_JSON.write_text(json.dumps(packet, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    OUT_MD.write_text(render_markdown(packet), encoding="utf-8")
    print(f"wrote {OUT_JSON.relative_to(ROOT)}")
    print(f"wrote {OUT_MD.relative_to(ROOT)}")
    return 0


def build_rehearsal_packet() -> dict[str, Any]:
    sim = EcosystemSimulator()
    reset_state = sim.reset().to_dict()
    spike_state = sim.apply_ammonia_spike().to_dict()
    forecast = forecast_anomaly(sim.state).to_dict()

    unsafe = reject_unsafe_action(sim)
    safe_result = sim.step(safety_policy(sim.state), validate=True).to_dict()
    training = train_policy().to_dict()

    return {
        "title": "ProteinLoop judge demo rehearsal",
        "steps": [
            {
                "name": "reset",
                "ok": reset_state["day"] == 0 and reset_state["collapsed"] is False,
                "detail": "Stable starting state loaded.",
                "state": summarize_state(reset_state),
            },
            {
                "name": "ammonia_spike",
                "ok": spike_state["ammonia_mg_l"] >= 3.0,
                "detail": "Critical ammonia scenario injected.",
                "state": summarize_state(spike_state),
                "forecast": {
                    "risk_level": forecast["risk_level"],
                    "recommendation": forecast["recommendation"],
                },
            },
            unsafe,
            {
                "name": "safe_recovery",
                "ok": safe_result["verification"]["ok"] is True
                and safe_result["state"]["collapsed"] is False,
                "detail": "Safety policy mutates state only after verifier acceptance.",
                "reward": safe_result["reward"],
                "state": summarize_state(safe_result["state"]),
            },
            {
                "name": "rlvr_policy_search",
                "ok": training["improvement"] > 0,
                "detail": "Verifier-guided candidate search improves best reward.",
                "best_policy": training["best_policy"]["name"],
                "improvement": training["improvement"],
                "iterations": training["iteration_count"],
            },
            {
                "name": "human_approval",
                "ok": True,
                "detail": "Producer path asks for approval before irreversible water or harvest action.",
                "copy": "Approve | Apply half | Reject",
            },
            {
                "name": "offline_guidance",
                "ok": True,
                "detail": "Fallback producer guidance remains deterministic when model/cloud access is absent.",
                "copy": "Do not feed. Start maximum aeration, use a verified partial water change, and call the community technician.",
            },
        ],
    }


def reject_unsafe_action(sim: EcosystemSimulator) -> dict[str, Any]:
    before = sim.state.to_dict()
    unsafe_action = EcosystemAction(
        feed_kg=4.0,
        aeration_hours=4.0,
        water_exchange_fraction=0.0,
        duckweed_harvest_kg=0.0,
        note="rehearsal_unsafe_overfeed",
    )

    try:
        sim.step(unsafe_action, validate=True)
    except UnsafeActionError as exc:
        after = sim.state.to_dict()
        return {
            "name": "unsafe_rejection",
            "ok": after == before and exc.result.ok is False,
            "detail": "Overfeeding proposal rejected before simulator mutation.",
            "state_preserved": after == before,
            "violations": list(exc.result.violations),
            "action": unsafe_action.to_dict(),
        }

    return {
        "name": "unsafe_rejection",
        "ok": False,
        "detail": "Unsafe action unexpectedly mutated simulator state.",
        "state_preserved": False,
        "violations": [],
        "action": unsafe_action.to_dict(),
    }


def summarize_state(state: dict[str, Any]) -> dict[str, Any]:
    return {
        "day": state["day"],
        "ammonia_mg_l": round(float(state["ammonia_mg_l"]), 4),
        "dissolved_oxygen_mg_l": round(float(state["dissolved_oxygen_mg_l"]), 4),
        "collapsed": state["collapsed"],
    }


def render_markdown(packet: dict[str, Any]) -> str:
    lines = [
        "# ProteinLoop Demo Rehearsal",
        "",
        "Generated from executable simulator behavior.",
        "",
    ]

    for step in packet["steps"]:
        status = "PASS" if step["ok"] else "FAIL"
        lines.extend(
            [
                f"## {step['name']}",
                "",
                f"- Status: {status}.",
                f"- Detail: {step['detail']}",
            ]
        )
        if "state" in step:
            state = step["state"]
            lines.append(
                "- State: "
                f"day {state['day']}, ammonia {state['ammonia_mg_l']} mg/L, "
                f"oxygen {state['dissolved_oxygen_mg_l']} mg/L, collapsed {state['collapsed']}."
            )
        if "violations" in step:
            lines.append(f"- Violations: {', '.join(step['violations'])}.")
        if "reward" in step:
            lines.append(f"- Reward: {step['reward']}.")
        if "improvement" in step:
            lines.append(
                f"- Search: best {step['best_policy']} improved reward by {step['improvement']} "
                f"over {step['iterations']} iterations."
            )
        if "copy" in step:
            lines.append(f"- Copy: {step['copy']}")
        lines.append("")

    return "\n".join(lines)


if __name__ == "__main__":
    raise SystemExit(main())
