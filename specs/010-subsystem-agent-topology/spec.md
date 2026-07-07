# Feature Spec: Subsystem Agent Topology

## Goal

Make the multi-agent story visible in the operator dashboard with named subsystem agents that evaluate the current simulator state and surface resource tensions.

## Functional Requirements

### FR-001: Named Subsystem Agents

The app shall derive deterministic status cards for fish tank, hydroponia, duckweed/chickens, and supervisor agents.

### FR-002: State-Based Recommendations

Each subsystem agent shall report a status, current focus, recommendation, and tension score from the current simulator state.

### FR-003: Dashboard Visibility

The operator dashboard shall render the subsystem topology without mutating simulator state.

### FR-004: Harness Boundary

Subsystem recommendations shall remain advisory. Simulator mutation shall continue to happen only through existing verified actions.

## Acceptance Criteria

1. Unit tests prove critical ammonia raises fish tank and supervisor risk.
2. Unit tests prove stable state keeps all subsystem agents non-critical.
3. The operator dashboard renders subsystem agent topology.
4. Phoenix tests pass.
5. Docker Compose serves the updated dashboard.
