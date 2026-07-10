# Implementation Plan: Agentic Intervention Mission

1. Add runtime tests that observe model messages and require mission/pre-state output.
2. Add LiveView tests for mission selection, async execution, duplicate protection, and the intelligence receipt.
3. Thread a normalized mission through subsystem prompts, supervisor prompt/state, and runtime results.
4. Extend the test runtime with realistic specialist briefs and before/after state.
5. Replace the compact Sagents summary with the mission selector, running state, specialist briefs, supervisor plan, verifier receipt, and outcome delta.
6. Run the mission against local Gemma 4 E2B and refresh executable evidence.
7. Rebuild Docker, verify the served operator route, regenerate submission artifacts, and publish.

## Guardrails

- The mission changes model context, never verifier limits.
- Show structured outputs and decisions, not hidden chain-of-thought.
- Keep one async mission in flight per LiveView.
- Preserve existing runtime and HITL entry points.
- Do not add a new model or frontend dependency.
