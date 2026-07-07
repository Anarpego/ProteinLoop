# Feature Spec: Agent Harness and Model Boundary

## Goal

Add the first ProteinLoop agent harness: a structured action proposer behind a `GEMMA_ENDPOINT` boundary, deterministic verifier execution through the simulator API, and dashboard evidence for both accepted and rejected proposals.

## Functional Requirements

### FR-001: Model Boundary

The app shall provide an OpenAI-compatible model client configured by environment:

- `GEMMA_ENDPOINT`
- `GEMMA_API_KEY`
- `GEMMA_MODEL`

The app shall not require real model credentials for local tests or demos.

### FR-002: Stub Proposers

The app shall provide deterministic stub proposers:

- safe stub: emits a context-aware action;
- unsafe stub: emits an intentionally unsafe overfeeding action for harness rejection demos.

### FR-003: Harness Execution

The harness shall:

1. read current simulator state;
2. request a structured action from the configured proposer;
3. submit that action to the simulator verifier via `/step`;
4. return an accepted or rejected result without bypassing verifier rules.

### FR-004: Dashboard Evidence

The operator dashboard shall include controls for safe and unsafe agent proposals and shall show whether the simulator accepted or rejected the proposal.

### FR-005: Spanish HITL Reuse

The producer route shall continue to use the same structured action contract so it can be swapped to the agent harness later.

## Acceptance Criteria

1. Safe stub proposals execute through the harness.
2. Unsafe stub proposals are rejected with verifier violations.
3. The model boundary can parse a JSON action from OpenAI-compatible chat output.
4. Operator LiveView renders agent proposal controls.
5. Python and Elixir tests pass.

