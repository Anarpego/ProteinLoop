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
NORDIC_NCS_340_SOURCE = "https://github.com/nrfconnect/sdk-nrf/releases/tag/v3.4.0"


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
        "status": "live_bidirectional_dect_verified",
        "hardware_inventory": {
            "available_boards": 2,
            "board_family": "Nordic nRF9151 DK PCA10171",
            "note": "Both J-Link devices were enumerated and captured live on 2026-07-10.",
        },
        "sdk_research": {
            "source": NORDIC_NCS_340_SOURCE,
            "researched_at": "2026-07-10",
            "installed_ncs_version": "3.3.1",
            "latest_stable_ncs_version": "3.4.0",
            "decision": "Preserve the known-good 3.3.1 board builds during read-only evidence capture; do not reflash solely for evidence.",
        },
        "live_evidence": {
            "json": "submission/nrf9151-live-evidence.json",
            "markdown": "submission/nrf9151-live-evidence.md",
            "capture_mode": "read_only_posix_serial",
            "simulated": False,
            "flash_or_reset_invoked": False,
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
                "jlink_id": "1051239227",
                "firmware_role": "PT",
                "serial_port": "/dev/cu.usbmodem0010512392271",
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
                "jlink_id": "1051223739",
                "firmware_role": "FT",
                "serial_port": "/dev/cu.usbmodem0010512237391",
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
            "Show submission/nrf9151-live-evidence.md as physical bidirectional DECT NR+ proof.",
            "Show PT 1051239227 as tank edge node and FT 1051223739 as gateway/controller.",
            "Run ProteinLoop dashboard self-healing mesh control to mirror board A loss and state-token migration.",
            "Use the separate sample telemetry bridge to explain future sensor payload mapping without claiming stock hello_dect logs contain water-quality values.",
        ],
        "non_blocking_scope": [
            "No firmware dependency is required for lablab submission.",
            "The recorded live RF artifact is validated in CI; connected hardware is not required for Docker smoke or replaying software tests.",
            "The real Sagents/Horde evidence is the authoritative software failover proof; the dashboard mesh remains the deterministic rehearsal.",
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
        f"- Board family: {plan['hardware_inventory']['board_family']}.",
        f"- Note: {plan['hardware_inventory']['note']}",
        "",
        "## SDK Research",
        "",
        f"- Official release: {plan['sdk_research']['source']}",
        f"- Installed NCS: {plan['sdk_research']['installed_ncs_version']}.",
        f"- Latest stable NCS researched: {plan['sdk_research']['latest_stable_ncs_version']}.",
        f"- Decision: {plan['sdk_research']['decision']}",
        "",
        "## Live Evidence",
        "",
        f"- Markdown: `{plan['live_evidence']['markdown']}`.",
        f"- Capture mode: `{plan['live_evidence']['capture_mode']}`.",
        f"- Simulated: {str(plan['live_evidence']['simulated']).lower()}.",
        f"- Flash or reset invoked: {str(plan['live_evidence']['flash_or_reset_invoked']).lower()}.",
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
                f"- J-Link: `{board['jlink_id']}`.",
                f"- Firmware role: {board['firmware_role']}.",
                f"- Serial port: `{board['serial_port']}`.",
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
