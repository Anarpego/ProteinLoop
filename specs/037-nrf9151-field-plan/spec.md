# Feature Spec: nRF9151 Two-Board Field Plan

## Goal

Capture the two available nRF9151 DECT NR+ boards as a concrete field-extension plan for ProteinLoop without making the hackathon software demo depend on hardware access.

## User Value

The team can explain how the local self-healing mesh maps to real DECT NR+ hardware while keeping the judged demo runnable in Docker.

## Functional Requirements

1. The repo shall include a stdlib-only generator for an nRF9151 two-board field plan.
2. The generator shall write `submission/nrf9151-field-plan.json` and `submission/nrf9151-field-plan.md`.
3. The plan shall define two board roles: tank sensor edge node and community gateway/controller.
4. The plan shall map board telemetry into ProteinLoop simulator fields.
5. The plan shall include a staged demo path that separates offline bench testing from the required Docker software demo.
6. The plan shall cite current official Nordic nRF9151 capabilities used by the plan.
7. The submission artifact validator shall require the generated field plan.

## Acceptance Criteria

1. `make nrf9151-plan` writes both field plan artifacts.
2. Unit tests prove the plan contains exactly two boards and required telemetry mappings.
3. `make submission-check` validates the generated field plan.
4. `make test` passes.
