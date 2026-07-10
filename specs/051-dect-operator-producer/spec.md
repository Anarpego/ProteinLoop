# Feature Spec: DECT Evidence In Operator And Producer Views

## Goal

Expose the latest two-board nRF9151 DECT NR+ capture in the live application and connect it to an explicit simulated sensor replay and the verified Sagents/Gemma loop.

## User Value

An operator can see that the physical FT and PT boards exchanged a real radio message, replay that captured event into the deterministic simulator, and then ask Gemma-backed agents to propose and verify a response. A producer can see the latest radio status without confusing the hello_dect packet with chemical sensor telemetry.

## Functional Requirements

1. The application shall load the latest committed `submission/nrf9151-live-evidence.json` artifact through a replaceable evidence provider.
2. The evidence contract shall report availability, capture time, simulated status, latest matching sequence, FT and PT identities, roles, serial ports, and peer exchange status.
3. The operator view shall display the latest physical DECT link and distinguish it from simulated water-quality telemetry.
4. The operator shall be able to refresh the evidence without restarting the application.
5. The operator shall be able to replay the DECT capture as a simulated sensor alert by invoking the existing deterministic ammonia-spike scenario.
6. The operator shall be able to start the existing verified Sagents/Gemma cycle from the DECT panel.
7. The producer view shall display a compact Spanish summary of the latest physical FT/PT exchange.
8. Both views shall state that Nordic `hello_dect` proves radio transport, not a physical chemical-sensor reading.
9. Docker profiles shall mount the committed evidence read-only so local and containerized views show the same capture.
10. Missing or malformed evidence shall render an unavailable state and shall not crash either LiveView.

## Acceptance Criteria

1. Unit tests parse the real evidence shape, select the latest matching sequence, and handle unavailable or invalid evidence.
2. LiveView tests prove both pages display sequence `#100`, both J-Link identities, and the real-radio versus simulated-telemetry disclosure.
3. A LiveView test proves replaying the capture invokes the simulator scenario and updates operator state.
4. A LiveView test proves the DECT Gemma action starts the same verified Sagents cycle as the existing operator control.
5. Phoenix tests pass and Docker-served `/` and `/producer` visibly contain the new DECT status.
