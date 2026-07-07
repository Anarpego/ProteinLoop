# Feature Spec: Self-Healing Mesh Demo

## Goal

Show the self-healing agent story from `goal.md` in the runnable demo: when a mesh node fails, subsystem agents migrate to healthy nodes while preserving their identities.

## Functional Requirements

### FR-001: Mesh Model

The app shall provide a deterministic mesh model with multiple nodes and assigned subsystem agents.

### FR-002: Node Failure

The operator dashboard shall provide a control that marks one edge node offline and migrates its agents to healthy nodes.

### FR-003: Node Recovery

The operator dashboard shall provide a control that marks the failed node online again.

### FR-004: Visible Migration Evidence

The dashboard shall show node status, agent placement, migration count, and recent mesh events.

## Acceptance Criteria

1. Unit tests prove agents on a failed node migrate to online nodes.
2. Unit tests prove agent identity is preserved after migration.
3. The operator dashboard renders self-healing mesh controls and state.
4. Phoenix tests pass.
5. Docker Compose serves the updated dashboard.
