# Feature Spec: Deterministic Loop Fallback

Status: superseded as the primary runtime by `specs/047-real-sagents-runtime/`.

## Goal

Preserve the original credential-free loop demonstration as a deterministic fallback for tests and offline judge rehearsal.

## User Value

Judges can see that ProteinLoop is not only a dashboard around a simulator. The agent path has a deterministic harness step that validates every action before mutation and can loop until a verifiable cycle result is produced.

## Functional Requirements

1. The app shall retain a deterministic loop runner with explicit named execution steps.
2. The loop runner shall include `verify_ecosystem_safety` before any simulator mutation.
3. The loop runner shall stop with a structured tool result when it reaches the configured `until_tool`.
4. The loop runner shall reject unsafe proposals without mutating simulator state.
5. The fallback shall remain independently unit-testable.
6. The implementation shall not require live model credentials.

## Acceptance Criteria

1. Unit tests prove accepted loop completion returns `{:ok, state, tool_result}`-equivalent data.
2. Unit tests prove unsafe proposals stop at `verify_ecosystem_safety` and preserve original state.
3. Phoenix tests pass.

The real dashboard/runtime acceptance criteria now live in spec 047.
