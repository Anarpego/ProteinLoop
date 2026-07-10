# ProteinLoop nRF9151 Field Plan

Status: `live_bidirectional_dect_verified`

## Hardware Inventory

- Available boards: 2.
- Board family: Nordic nRF9151 DK PCA10171.
- Note: Both J-Link devices were enumerated and captured live on 2026-07-10.

## SDK Research

- Official release: https://github.com/nrfconnect/sdk-nrf/releases/tag/v3.4.0
- Installed NCS: 3.3.1.
- Latest stable NCS researched: 3.4.0.
- Decision: Preserve the known-good 3.3.1 board builds during read-only evidence capture; do not reflash solely for evidence.

## Live Evidence

- Markdown: `submission/nrf9151-live-evidence.md`.
- Capture mode: `read_only_posix_serial`.
- Simulated: false.
- Flash or reset invoked: false.

## Official Capability Basis

- Source: https://www.nordicsemi.com/Products/nRF9151
- nRF9151 is a System-in-Package for LTE-M, NB-IoT, NTN, DECT NR+, and GNSS.
- Nordic lists 915 MHz and 1.9 GHz NR+ band support.
- Nordic lists nRF9151 DK and nRF9151 SMA DK as DECT NR+ development kits.
- The application processor is an Arm Cortex-M33 with 1 MB flash and 256 KB RAM.

## Board Roles

### nr9151-tank-edge-a

- Role: tank sensor edge node.
- J-Link: `1051239227`.
- Firmware role: PT.
- Serial port: `/dev/cu.usbmodem0010512392271`.
- Placement: main fish/prawn tank.
- ProteinLoop agent: fish-tank.
- Telemetry: ammonia_mg_l, dissolved_oxygen_mg_l, temperature_c.
- Responsibilities:
  - publish water-quality readings
  - emit ammonia spike event for demo rehearsal
  - act as the failure target for mesh migration storytelling

### nr9151-community-gateway-b

- Role: community gateway/controller.
- J-Link: `1051223739`.
- Firmware role: FT.
- Serial port: `/dev/cu.usbmodem0010512237391`.
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
2. Show submission/nrf9151-live-evidence.md as physical bidirectional DECT NR+ proof.
3. Show PT 1051239227 as tank edge node and FT 1051223739 as gateway/controller.
4. Run ProteinLoop dashboard self-healing mesh control to mirror board A loss and state-token migration.
5. Use the separate sample telemetry bridge to explain future sensor payload mapping without claiming stock hello_dect logs contain water-quality values.

## Non-Blocking Scope

- No firmware dependency is required for lablab submission.
- The recorded live RF artifact is validated in CI; connected hardware is not required for Docker smoke or replaying software tests.
- The real Sagents/Horde evidence is the authoritative software failover proof; the dashboard mesh remains the deterministic rehearsal.
