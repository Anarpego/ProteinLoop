# Implementation Plan: Model Endpoint Status

## Architecture

- Add `ProteinLoop.Agent.ModelStatus`.
- Reuse the existing `Req` dependency for OpenAI-compatible `/v1/models` checks.
- Keep network access behind an explicit dashboard action so LiveView mount remains fast.
- Render the status inside the existing Agent harness panel.

## Verification

- Test `ModelStatus` with injected request functions instead of external HTTP.
- Update route test for the new dashboard text.
- Run Phoenix and Python tests.
- Rebuild Docker Compose and verify route text.
