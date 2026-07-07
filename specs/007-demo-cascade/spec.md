# Feature Spec: One-Click Demo Cascade

## Goal

Provide a repeatable judge demo that runs the core ProteinLoop story end to end from one dashboard control.

## Functional Requirements

### FR-001: Demo Sequence

The app shall provide a demo cascade that:

1. resets the simulator;
2. injects an ammonia spike;
3. runs an unsafe agent proposal and records verifier rejection;
4. runs a safe agent proposal and records verifier acceptance;
5. returns the final simulator state and trace status.

### FR-002: Dashboard Control

The operator dashboard shall include a `Run demo cascade` control and display the latest cascade result.

### FR-003: Trace Integration

The unsafe and safe proposal outcomes shall be recorded through the existing JSONL trace store.

## Acceptance Criteria

1. Unit tests prove the cascade produces a rejected unsafe step and an accepted safe step.
2. The operator dashboard renders the demo cascade control.
3. Python and Phoenix tests pass.
4. Docker Compose rebuilds and serves the updated dashboard.

