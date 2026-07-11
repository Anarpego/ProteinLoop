# Implementation Plan: AMD Gemma Verifier-Guided Search

1. Add failing deterministic candidate-ranking tests.
2. Implement a simulator-owned evaluator with no network dependency.
3. Add an AMD pod runner that requests diverse Gemma candidates and writes evidence.
4. Add Make and optional bundle integration.
5. Run regression checks and publish for pod execution.

## Guardrails

- Do not describe Best-of-N inference as RL training or fine-tuning.
- Never execute a candidate that fails `SafetyVerifier`.
- Use the same initial state for all comparisons.
- Record structured outputs and rewards, not hidden reasoning text.
