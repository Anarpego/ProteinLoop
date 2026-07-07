# Feature Spec: Spanish HITL Approval Queue

## Goal

Connect the producer-facing Spanish approval screen to the agent/operator flow so irreversible actions are paused for human decision before they can mutate simulator state.

## User Value

Judges can see the harness stop at a risky water/harvest action, ask the producer in Spanish, and continue only after approve/edit/reject. The flow demonstrates human-in-the-loop as control flow, not static UI.

## Functional Requirements

1. The operator dashboard shall provide a control that creates a pending risky action requiring producer approval.
2. The pending action shall include Spanish prompt text and action details for water exchange and duckweed harvest.
3. `/producer` shall render the pending action when present, with `Aprobar`, `Solo mitad`, and `Rechazar` controls.
4. Approving a pending action shall execute it through the simulator `/step` boundary.
5. Editing a pending action shall reduce the irreversible portions before executing through `/step`.
6. Rejecting a pending action shall resolve the approval without mutating simulator state.
7. The operator dashboard shall show whether the queue is idle or waiting for producer decision.

## Acceptance Criteria

1. Unit tests cover queue request, edit, approve/resolve, reject/resolve, and reset behavior.
2. Route tests prove the operator dashboard exposes the HITL queue and `/producer` renders Spanish approval controls.
3. Phoenix tests pass.
4. Docker Compose serves the updated dashboard and producer route.
