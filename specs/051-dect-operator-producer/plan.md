# Implementation Plan: DECT Evidence In Operator And Producer Views

1. Add parser and LiveView tests for the DECT evidence contract and new controls.
2. Implement a replaceable evidence provider with a safe unavailable fallback.
3. Add the operator evidence panel, simulated replay action, refresh action, and Sagents/Gemma action.
4. Add the producer Spanish evidence summary and disclosure.
5. Mount the submission evidence read-only in Docker profiles.
6. Update run and demo documentation.
7. Run Phoenix tests, rebuild the services, and verify both routes from the running application.

## Guardrails

- Never label `hello_dect` traffic as a physical ammonia, oxygen, pH, or temperature measurement.
- Never mutate or flash either connected nRF9151 board from the web application.
- Reuse the deterministic simulator scenario and verified Sagents runtime.
- Treat the JSON artifact as untrusted input and render a stable unavailable state on failure.
