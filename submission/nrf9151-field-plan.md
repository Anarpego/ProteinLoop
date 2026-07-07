# ProteinLoop nRF9151 Field Plan

Status: `hardware_available_not_required_for_submission`

## Hardware Inventory

- Available boards: 2.
- Assumed family: Nordic nRF9151 DK or nRF9151 SMA DK.
- Note: User reported two DECT NR+ nRF9151 boards on 2026-07-07.

## Official Capability Basis

- Source: https://www.nordicsemi.com/Products/nRF9151
- nRF9151 is a System-in-Package for LTE-M, NB-IoT, NTN, DECT NR+, and GNSS.
- Nordic lists 915 MHz and 1.9 GHz NR+ band support.
- Nordic lists nRF9151 DK and nRF9151 SMA DK as DECT NR+ development kits.
- The application processor is an Arm Cortex-M33 with 1 MB flash and 256 KB RAM.

## Board Roles

### nr9151-tank-edge-a

- Role: tank sensor edge node.
- Placement: main fish/prawn tank.
- ProteinLoop agent: fish-tank.
- Telemetry: ammonia_mg_l, dissolved_oxygen_mg_l, temperature_c.
- Responsibilities:
  - publish water-quality readings
  - emit ammonia spike event for demo rehearsal
  - act as the failure target for mesh migration storytelling

### nr9151-community-gateway-b

- Role: community gateway/controller.
- Placement: operator or shared village node.
- ProteinLoop agent: supervisor.
- Telemetry: node_online, battery_mv, link_quality.
- Responsibilities:
  - receive tank edge telemetry
  - bridge field readings to the Phoenix dashboard
  - remain online when tank edge node is simulated as failed

## Telemetry Mapping

- `ammonia_mg_l` -> sim/proteinloop_sim/state.py::EcosystemState.ammonia_mg_l
- `dissolved_oxygen_mg_l` -> sim/proteinloop_sim/state.py::EcosystemState.dissolved_oxygen_mg_l
- `temperature_c` -> sim/proteinloop_sim/state.py::EcosystemState.temperature_c
- `node_online` -> app/lib/proteinloop/agent/mesh.ex node online? status
- `battery_mv` -> future dashboard sensor detail; not required for simulator mutation
- `link_quality` -> future dashboard sensor detail; not required for simulator mutation

## Demo Path

1. Keep the judged software demo Docker-runnable without hardware.
2. Use the two nRF9151 boards as optional bench props for the DECT NR+ scale story.
3. Show board A as tank edge node and board B as gateway/controller.
4. Run ProteinLoop dashboard self-healing mesh control to mirror board A loss and state-token migration.
5. If firmware time permits, stream board telemetry into the simulator API instead of manual spike injection.

## Non-Blocking Scope

- No firmware dependency is required for lablab submission.
- No live RF link is required for Docker smoke, CI, or final readiness checks.
- The deterministic mesh evidence remains the authoritative software proof.
