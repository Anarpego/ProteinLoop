# Feature Spec: Provider Control and RLVR Traces

## Goal

Make the agent harness demo useful for model integration and RLVR by allowing operator-selected providers and recording every proposal/verifier outcome as JSONL trace data.

## Functional Requirements

### FR-001: Provider Selection

The operator dashboard shall allow these harness providers:

- safe stub;
- unsafe stub;
- OpenAI-compatible model provider.

### FR-002: Trace Recording

Each harness run shall record a JSONL trace containing:

- timestamp;
- provider;
- accepted/rejected status;
- original simulator state;
- proposed action;
- verifier result;
- resulting simulator state;
- reward if accepted;
- metadata/rationale.

### FR-003: Trace Visibility

The operator dashboard shall show the latest trace path and trace count.

### FR-004: Testability

Trace recording must be testable without network, model credentials, or a running simulator.

## Acceptance Criteria

1. Harness tests prove accepted and rejected runs are recorded.
2. Trace JSONL entries are valid JSON.
3. Operator dashboard renders provider controls and trace status.
4. Python and Elixir tests pass.

