# Feature Spec: Agentic Intervention Mission

## Goal

Turn the operator's Gemma control from a data-summary panel into a user-directed intervention mission that visibly detects context, delegates to specialists, synthesizes a plan, proves safety, mutates state, and explains the outcome.

## User Value

An operator can choose an operational objective and receive an intelligence receipt showing what each specialist recommended, what the supervisor decided, why the deterministic verifier allowed the action, and what changed in the ecosystem.

## Functional Requirements

1. The operator shall choose among concise mission presets for water recovery, protein protection, and balanced 24-hour operation.
2. The selected objective shall be included in the real prompts sent to all four Sagents subsystem agents and the parent supervisor.
3. The runtime result shall preserve the mission and the pre-action ecosystem state alongside the existing action, verification, reward, and resulting state.
4. The UI shall expose an `Agentic intervention mission` as a primary operational workflow, not another analytics chart.
5. While the mission runs, the UI shall show that specialist deliberation is active and prevent duplicate launches.
6. After completion, the UI shall render all four structured specialist briefs, including status, recommendation, and resource request.
7. The UI shall render the supervisor's structured action and model-generated action note.
8. The UI shall render a deterministic safety receipt with tool name, verifier status, violations, warnings, and reward.
9. The UI shall compare before and after ammonia, dissolved oxygen, and simulation day.
10. Existing DECT and `Run Gemma agents` controls shall execute the currently selected mission through the same runtime path.
11. The UI shall not expose hidden chain-of-thought or label deterministic summaries as model reasoning.
12. Simulator verification shall remain authoritative regardless of the selected mission.

## Acceptance Criteria

1. Runtime tests prove the selected mission reaches subsystem and supervisor model messages.
2. Runtime tests prove the result includes the exact mission and immutable pre-action state.
3. LiveView tests prove mission selection changes the objective passed to the runtime.
4. LiveView tests prove the running state is visible and duplicate mission events do not launch duplicate tasks.
5. LiveView tests prove the completed intelligence receipt displays four recommendations, the supervisor plan, verifier acceptance, and before/after values.
6. A real local Gemma 4 E2B mission completes through `close_cycle` and writes refreshed Sagents evidence.
7. Phoenix, Python, Docker smoke, and submission artifact checks pass.
