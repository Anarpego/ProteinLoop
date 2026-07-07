# Feature Spec: Simulator and Reward Verifier Vertical Slice

## Goal

Build the first executable ProteinLoop slice: a deterministic Python simulator that models a small aquaponic protein loop, validates proposed interventions, and produces a reward signal suitable for later RLVR training.

## Users

- Hackathon judge: wants to see a real system state evolve, fail, and recover.
- Agent harness: needs a deterministic verifier before executing model-proposed actions.
- Future LiveView dashboard: needs JSON state snapshots and events.

## Functional Requirements

### FR-001: Ecosystem State

The simulator shall represent water chemistry, organisms, and production outputs:

- ammonia concentration;
- nitrate concentration;
- dissolved oxygen;
- pH and temperature;
- fish biomass;
- prawn biomass;
- duckweed biomass;
- plant biomass;
- chicken egg count;
- mortality status.

### FR-002: Validated Actions

The verifier shall validate structured actions before they are applied. The first action contract shall include:

- feed amount in kg;
- aeration hours;
- water exchange fraction;
- duckweed harvest amount in kg;
- optional note.

### FR-003: Safety Rejection

The verifier shall reject actions that are physically unsafe or impossible, including overfeeding, excessive water exchange, harvesting unavailable duckweed, and negative values.

### FR-004: Daily Simulation Step

The simulator shall advance one day at a time and update chemistry, biomass, oxygen, waste, and mortality status.

### FR-005: Verifiable Reward

The verifier shall compute a reward from current state using survival, biomass, production, water stability, and resource-efficiency terms.

### FR-006: Collapse and Recovery Scenario

The simulator shall provide an ammonia spike scenario where:

- a naive control policy collapses or suffers severe risk;
- a safety-aware policy can stabilize the system.

### FR-007: HTTP Contract

The simulator shall expose a minimal JSON HTTP server with endpoints for state, reset, stepping, and triggering the ammonia spike.

## Acceptance Criteria

1. `python3 -m unittest discover -s tests` passes.
2. An overfeeding action is rejected before state mutation.
3. In tests, the naive policy performs worse than the safety-aware policy after an ammonia spike.
4. The CLI can run a demo and print final reward/mortality status.
5. The HTTP server returns JSON state and accepts JSON actions.

## Non-Goals

- Full biological realism.
- RL training loop.
- Phoenix LiveView UI.
- Real sensor hardware.
- Real LLM calls.

