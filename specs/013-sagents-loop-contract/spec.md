# Feature Spec: Sagents-Compatible Loop Contract

## Goal

Demonstrate the `goal.md` agentic loop contract in executable code: explicit pipeline steps, a custom verifier step named `verify_ecosystem_safety`, and structured termination through `until_tool`.

## User Value

Judges can see that ProteinLoop is not only a dashboard around a simulator. The agent path has a deterministic harness step that validates every action before mutation and can loop until a verifiable cycle result is produced.

## Functional Requirements

1. The app shall provide a loop runner with named execution steps compatible with Sagents' documented explicit pipeline style.
2. The loop runner shall include `verify_ecosystem_safety` before any simulator mutation.
3. The loop runner shall stop with a structured tool result when it reaches the configured `until_tool`.
4. The loop runner shall reject unsafe proposals without mutating simulator state.
5. The operator dashboard shall include a control to run the verified loop and show step trace, reward, final day, and tool result.
6. The implementation shall not require live model credentials for local tests or Docker demos.

## Acceptance Criteria

1. Unit tests prove accepted loop completion returns `{:ok, state, tool_result}`-equivalent data.
2. Unit tests prove unsafe proposals stop at `verify_ecosystem_safety` and preserve original state.
3. Route tests prove the operator dashboard renders the loop contract controls.
4. Phoenix tests pass.
5. Docker Compose serves the updated dashboard.
