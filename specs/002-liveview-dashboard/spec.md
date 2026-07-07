# Feature Spec: Phoenix LiveView Dashboard Slice

## Goal

Build the first Phoenix LiveView interface for ProteinLoop using the Python simulator API as the authoritative state source.

## Functional Requirements

### FR-001: Operator Dashboard

The app shall expose an English operator route at `/` showing simulator connectivity, ammonia, dissolved oxygen, day, reward, biomass, eggs, and recent events.

### FR-002: Simulator Controls

The operator route shall trigger an ammonia spike, apply the deterministic safety step, reset the scenario, and refresh state through the simulator API.

### FR-003: Producer HITL Route

The app shall expose a Spanish route at `/producer` showing a proposed action and controls to approve, edit to half feed, or reject the action.

### FR-004: PubSub State Flow

The app shall poll the simulator and broadcast snapshots through Phoenix.PubSub so LiveViews receive server-side updates.

### FR-005: Current Dependency Versions

Phoenix dependencies shall be verified against current official package sources before pinning in `mix.exs`.

## Acceptance Criteria

1. `/` renders the operator dashboard.
2. `/producer` renders Spanish approval controls.
3. Simulator client returns a critical-ammonia recovery action for high ammonia.
4. `mix.exs` pins verified current versions for added dependencies.
5. README documents how to run Phoenix alongside the simulator.

