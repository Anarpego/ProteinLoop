# Implementation Plan: Real Sagents Runtime

## Research Basis

- Sagents `0.9.0` is the latest stable Hex release verified on July 9, 2026.
- LangChain Elixir `0.9.2` is the latest stable release verified on July 9, 2026.
- Sagents `0.9.0` supports custom execution modes, `until_tool_success`, SubAgents, HumanInTheLoop middleware, OTP supervision, PubSub, and optional Horde distribution.
- LangChain `ChatOpenAI` supports custom OpenAI-compatible endpoints and forced function tools.
- Local Gemma 4 E2B has been verified to return OpenAI-compatible `tool_calls` when a function is forced.

## Vertical Slices

1. Add and test the simulator `/verify` contract.
2. Add pinned dependencies and `Sagents.Supervisor`.
3. Implement and unit-test `ProteinLoop.Agent.SafetyMode`.
4. Implement concurrent `Sagents.SubAgent` workers and a parent supervisor behind a small runtime module.
5. Prove local E2B `until_tool_success` execution and HITL interruption.
6. Surface honest runtime evidence in the operator dashboard and submission packet.
7. Add atomic HITL claims and server-side task guards for exact-once operator actions.

## Guardrails

- The Python verifier remains authoritative; model prompts and JSON schemas are only guidance.
- `/verify` must not mutate state, and `/step` must revalidate before mutation.
- The local runtime shall report local Sagents distribution honestly; deterministic mesh simulation shall not be labeled as real Horde migration.
- Tests shall use injected simulators or request adapters and shall not require live credentials.
- Repeated UI events shall be rejected by server state, even when browser controls are stale.

## Verification

- Run focused Python tests after `/verify` changes.
- Run focused ExUnit tests after each Sagents component.
- Run a real local E2B Sagents execution and preserve JSON evidence.
- Rebuild Docker images and rerun all repository and submission gates.
- Pause the test runtime to prove duplicate LiveView events start only one async task.
