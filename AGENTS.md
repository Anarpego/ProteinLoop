# ProteinLoop Agent Instructions

This repository follows a spec-first workflow inspired by GitHub Spec Kit and a disciplined agent workflow inspired by Superpowers.

## Operating Mode

1. Start from the current spec artifacts before changing code:
   - `.specify/memory/constitution.md`
   - `specs/*/spec.md`
   - `specs/*/plan.md`
   - `specs/*/tasks.md`
2. Keep implementation aligned with the active spec. If the product goal changes, update the spec before code.
3. Work in vertical slices that can be demonstrated end to end.
4. Use test-driven development for simulator, verifier, harness, and API behavior:
   - write or update a failing test for the intended behavior;
   - implement the smallest coherent change;
   - run the relevant tests;
   - refactor only after tests pass.
5. Before claiming completion, verify behavior from executable evidence, not intent.

## Hackathon Priorities

The non-negotiable core is:

1. Python simulator/verifier for a closed protein loop.
2. Agent harness that validates actions before they mutate simulator state.
3. Real-time operator demo with collapse-versus-recovery behavior.
4. Spanish human-in-the-loop approval for irreversible or risky actions.
5. Dockerized project with clear README instructions.

Cut optional work before compromising the core. Vision/VLM, real multi-node self-healing, and Raspberry Pi fallback are stretch goals.

## Engineering Guardrails

- Prefer deterministic domain rules over LLM judgment for safety checks.
- Treat simulator reward as the RLVR verifier source of truth.
- Keep model access behind `GEMMA_ENDPOINT` so Fireworks and AMD-hosted vLLM are swappable.
- Use plain data contracts between Python and Elixir/Phoenix so either side can be tested independently.
- Do not add large frameworks until a vertical slice needs them.

