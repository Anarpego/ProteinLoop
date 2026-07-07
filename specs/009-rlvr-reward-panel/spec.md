# Feature Spec: RLVR Reward Panel

## Goal

Show a lightweight, verifiable RLVR story in the demo: the simulator reward function scores a baseline policy against a safety-aware candidate policy across repeatable scenarios.

## Functional Requirements

### FR-001: Deterministic Evaluation Batch

The Python simulator shall evaluate naive and safety policies across fixed scenarios and return reward deltas, collapse recovery counts, and scenario details.

### FR-002: API Exposure

The simulator API shall expose the evaluation at `GET /rlvr/evaluation` without mutating simulator state.

### FR-003: Dashboard Panel

The operator dashboard shall show average reward delta, recovered scenarios, collapse avoidance rate, and per-scenario baseline/candidate rewards.

### FR-004: Offline Fallback

If the simulator API is unavailable, the dashboard shall render an offline RLVR status instead of crashing.

## Acceptance Criteria

1. Python tests prove the safety candidate improves reward and avoids at least one baseline collapse.
2. API tests prove `GET /rlvr/evaluation` returns the reward verifier payload.
3. Phoenix tests prove the dashboard renders the RLVR panel.
4. CLI `python -m proteinloop_sim rlvr` outputs JSON.
5. Docker Compose serves the updated dashboard.
