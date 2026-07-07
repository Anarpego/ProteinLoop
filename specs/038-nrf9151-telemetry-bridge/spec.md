# Feature Spec: nRF9151 Telemetry Bridge Contract

## Goal

Define and test a lightweight telemetry bridge contract for the two nRF9151 boards so board readings can be mapped into ProteinLoop demo actions without requiring live hardware in CI.

## User Value

The team can show exactly how DECT NR+ board messages become simulator or dashboard events, while keeping the software demo deterministic and Docker-runnable.

## Functional Requirements

1. The repo shall include a stdlib-only nRF9151 telemetry bridge script.
2. The bridge shall accept newline-delimited JSON telemetry records.
3. Tank-edge telemetry shall validate ammonia, oxygen, and temperature readings.
4. Critical tank-edge telemetry shall produce a simulator `/scenario/ammonia_spike` request payload.
5. Gateway node telemetry shall produce a dashboard mesh event hint when the edge node is offline.
6. The repo shall generate `submission/nrf9151-telemetry-bridge.json` and `.md` from sample two-board telemetry.
7. The submission artifact validator shall require the generated bridge evidence.

## Acceptance Criteria

1. `make nrf9151-bridge` writes both bridge evidence artifacts.
2. Unit tests prove critical tank telemetry maps to `/scenario/ammonia_spike`.
3. Unit tests prove gateway offline telemetry maps to a mesh failure hint.
4. `make submission-check` validates the generated bridge evidence.
5. `make test` passes.
