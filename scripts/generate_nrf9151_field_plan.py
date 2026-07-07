"""Generate the nRF9151 two-board field extension plan."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SUBMISSION = ROOT / "submission"
OUT_JSON = SUBMISSION / "nrf9151-field-plan.json"
OUT_MD = SUBMISSION / "nrf9151-field-plan.md"

NORDIC_NRF9151_SOURCE = "https://www.nordicsemi.com/Products/nRF9151"


def main() -> int:
    plan = build_plan()
    OUT_JSON.write_text(json.dumps(plan, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    OUT_MD.write_text(render_markdown(plan), encoding="utf-8")
    print(f"wrote {OUT_JSON.relative_to(ROOT)}")
    print(f"wrote {OUT_MD.relative_to(ROOT)}")
    return 0


def build_plan() -> dict[str, Any]:
    return {
        "title": "ProteinLoop nRF9151 two-board DECT NR+ field plan",
        "status": "hardware_available_not_required_for_submission",
        "hardware_inventory": {
            "available_boards": 2,
            "assumed_board_family": "Nordic nRF9151 DK or nRF9151 SMA DK",
            "note": "User reported two DECT NR+ nRF9151 boards on 2026-07-07.",
        },
        "official_capabilities": {
            "source": NORDIC_NRF9151_SOURCE,
            "summary": [
                "nRF9151 is a System-in-Package for LTE-M, NB-IoT, NTN, DECT NR+, and GNSS.",
                "Nordic lists 915 MHz and 1.9 GHz NR+ band support.",
                "Nordic lists nRF9151 DK and nRF9151 SMA DK as DECT NR+ development kits.",
                "The application processor is an Arm Cortex-M33 with 1 MB flash and 256 KB RAM.",
            ],
        },
        "boards": [
            {
                "id": "nr9151-tank-edge-a",
                "role": "tank sensor edge node",
                "placement": "main fish/prawn tank",
                "responsibilities": [
                    "publish water-quality readings",
                    "emit ammonia spike event for demo rehearsal",
                    "act as the failure target for mesh migration storytelling",
                ],
                "telemetry": ["ammonia_mg_l", "dissolved_oxygen_mg_l", "temperature_c"],
                "proteinloop_agent": "fish-tank",
            },
            {
                "id": "nr9151-community-gateway-b",
                "role": "community gateway/controller",
                "placement": "operator or shared village node",
                "responsibilities": [
                    "receive tank edge telemetry",
                    "bridge field readings to the Phoenix dashboard",
                    "remain online when tank edge node is simulated as failed",
                ],
                "telemetry": ["node_online", "battery_mv", "link_quality"],
                "proteinloop_agent": "supervisor",
            },
        ],
        "telemetry_mapping": {
            "ammonia_mg_l": "sim/proteinloop_sim/state.py::EcosystemState.ammonia_mg_l",
            "dissolved_oxygen_mg_l": "sim/proteinloop_sim/state.py::EcosystemState.dissolved_oxygen_mg_l",
            "temperature_c": "sim/proteinloop_sim/state.py::EcosystemState.temperature_c",
            "node_online": "app/lib/proteinloop/agent/mesh.ex node online? status",
            "battery_mv": "future dashboard sensor detail; not required for simulator mutation",
            "link_quality": "future dashboard sensor detail; not required for simulator mutation",
        },
        "demo_path": [
            "Keep the judged software demo Docker-runnable without hardware.",
            "Use the two nRF9151 boards as optional bench props for the DECT NR+ scale story.",
            "Show board A as tank edge node and board B as gateway/controller.",
            "Run ProteinLoop dashboard self-healing mesh control to mirror board A loss and state-token migration.",
            "If firmware time permits, stream board telemetry into the simulator API instead of manual spike injection.",
        ],
        "non_blocking_scope": [
            "No firmware dependency is required for lablab submission.",
            "No live RF link is required for Docker smoke, CI, or final readiness checks.",
            "The deterministic mesh evidence remains the authoritative software proof.",
        ],
    }


def render_markdown(plan: dict[str, Any]) -> str:
    lines = [
        "# ProteinLoop nRF9151 Field Plan",
        "",
        f"Status: `{plan['status']}`",
        "",
        "## Hardware Inventory",
        "",
        f"- Available boards: {plan['hardware_inventory']['available_boards']}.",
        f"- Assumed family: {plan['hardware_inventory']['assumed_board_family']}.",
        f"- Note: {plan['hardware_inventory']['note']}",
        "",
        "## Official Capability Basis",
        "",
        f"- Source: {plan['official_capabilities']['source']}",
    ]

    lines.extend(f"- {item}" for item in plan["official_capabilities"]["summary"])
    lines.extend(["", "## Board Roles", ""])

    for board in plan["boards"]:
        lines.extend(
            [
                f"### {board['id']}",
                "",
                f"- Role: {board['role']}.",
                f"- Placement: {board['placement']}.",
                f"- ProteinLoop agent: {board['proteinloop_agent']}.",
                f"- Telemetry: {', '.join(board['telemetry'])}.",
                "- Responsibilities:",
            ]
        )
        lines.extend(f"  - {item}" for item in board["responsibilities"])
        lines.append("")

    lines.extend(["## Telemetry Mapping", ""])
    lines.extend(f"- `{key}` -> {value}" for key, value in plan["telemetry_mapping"].items())

    lines.extend(["", "## Demo Path", ""])
    lines.extend(f"{index}. {step}" for index, step in enumerate(plan["demo_path"], start=1))

    lines.extend(["", "## Non-Blocking Scope", ""])
    lines.extend(f"- {item}" for item in plan["non_blocking_scope"])
    lines.append("")
    return "\n".join(lines)


if __name__ == "__main__":
    raise SystemExit(main())
