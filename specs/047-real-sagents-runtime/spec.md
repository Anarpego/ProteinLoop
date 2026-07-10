# Feature Spec: Real Sagents Runtime

## Goal

Supersede the dependency-free loop demonstration with an executable Sagents runtime that orchestrates ProteinLoop through the deterministic simulator boundary.

## Functional Requirements

1. The Phoenix application shall depend on the latest verified stable Sagents and LangChain Elixir releases and start `Sagents.Supervisor` under its OTP supervision tree.
2. The simulator shall expose a non-mutating `/verify` endpoint that evaluates an action against the current state and returns the same verifier result used by `/step`.
3. ProteinLoop shall implement a real Sagents custom execution mode containing a named `verify_ecosystem_safety` step before `execute_tools`.
4. Unsafe tool arguments shall terminate before tool execution and shall not mutate simulator state.
5. Fish tank, freshwater prawn, hydroponia, and duckweed/chickens work shall be represented by four real subsystem `Sagents.Agent` instances executing concurrently, followed by a parent supervisor agent.
6. The supervisor agent shall terminate through Sagents `until_tool_success` using a structured `close_cycle` tool result.
7. Irreversible water/harvest actions shall be protected by `Sagents.Middleware.HumanInTheLoop` with approve, edit, and reject decisions.
8. Runtime status and evidence shall identify actual Sagents version, execution mode, subsystem agents, verifier step, and termination tool without claiming Horde distribution when running locally.
9. The runtime shall use the existing `GEMMA_ENDPOINT` and `GEMMA_MODEL` OpenAI-compatible contract and remain testable without network or model credentials.
10. A pending HITL tool call shall be claimed atomically so concurrent or repeated producer events cannot execute it more than once.

## Acceptance Criteria

1. Simulator tests prove `/verify` accepts safe actions, rejects unsafe actions, and never changes state.
2. Phoenix tests prove the custom Sagents verifier step blocks unsafe tool calls before the function body executes.
3. Phoenix tests prove the runtime builds four named subsystem agents plus a supervisor, includes SubAgent and HITL middleware, and uses the custom mode.
4. A real local E2B run completes through Sagents `until_tool_success`, returns verifier evidence, and advances simulator state.
5. A real or deterministic Sagents HITL run interrupts before mutation and exposes approve/edit/reject decisions.
6. Python, Phoenix, Docker, live-demo, and submission checks pass after the integration.
7. Phoenix tests prove duplicate operator events do not launch duplicate agent tasks and a claimed producer action cannot resume twice.
