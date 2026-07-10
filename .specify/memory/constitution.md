# ProteinLoop Constitution

## Principles

### I. Spec Is the Source of Product Intent

Every feature starts with a spec describing user value, acceptance criteria, and measurable behavior. Code may evolve quickly during the hackathon, but product intent must remain visible in `specs/`.

### II. Verifiable Safety Beats Persuasive Output

The LLM may propose actions, but deterministic code decides whether an action is safe enough to execute. Any feed, water exchange, harvest, or intervention must pass the harness verifier before it changes ecosystem state.

### III. End-to-End Demo Over Isolated Sophistication

Prefer one complete flow that runs locally and in Docker over disconnected advanced components. A narrow working simulator plus harness plus UI is more valuable than unintegrated RL, vision, or cluster demos.

### IV. Test the Physics Contract

Simulator rules, reward functions, safety thresholds, and API contracts require automated tests. Tests should prove the behaviors the pitch depends on: collapse without intervention, recovery with safe intervention, and rejection of unsafe actions.

### V. Plain-Language English Producer UX Is a Product Requirement

The producer-facing path must use direct English action language. It should ask for approval or edits before irreversible actions and explain technical conditions in everyday terms.

### VI. Show the Living System Before the Metrics

The primary interface must visually identify the tank, plants, duckweed, chickens, and resource flow. Plain-language health meaning appears before technical chemistry names or analytics.

### VII. Simple by Default, Evidence on Demand

The default operator view must present one condition, one recommended priority, and one primary AI action. Engineering telemetry and proof remain available behind an explicitly opened advanced section.

### VIII. Motion Must Encode System Truth

Real-time graphics must respond to simulator state rather than play as unrelated decoration. Water quality, animal behavior, oxygenation, and alerts must remain traceable to deterministic values, while the Python simulator remains the only source of ecosystem truth.

## Technical Constraints

- Python owns simulator, verifier, scenarios, reward, and RLVR hooks.
- Elixir/Phoenix will own orchestration, LiveView, PubSub, and HITL.
- Model calls must be OpenAI-compatible through environment configuration.
- The project must remain Docker-runnable for submission.

## Definition of Done

A feature is done only when:

1. Spec/plan/tasks are updated or confirmed unchanged.
2. Code is implemented.
3. Relevant tests pass.
4. README or run instructions are updated when behavior changes.
5. The delivered behavior can be verified from commands, tests, or runtime output.
