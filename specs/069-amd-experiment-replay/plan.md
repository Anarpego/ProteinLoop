# Implementation Plan: AMD Experiment Replay

1. Add a pure Elixir evidence loader that validates and joins the two imported JSON artifacts.
2. Add unit fixtures and failing tests for valid, missing, mismatched, and failed evidence.
3. Inject the evidence snapshot into `OperatorLive` through the existing testable dependency pattern.
4. Replace portable-only AMD messaging with a captured-run replay when validated evidence exists.
5. Show provenance, runtime, candidate outcomes, selected action, and reward impact in plain English.
6. Mount the submission artifacts read-only in local, Horde, and public Docker profiles.
7. Import the real pod artifacts and update submission-facing documentation and generated assets.
8. Run focused tests, full suites, readiness checks, and desktop/mobile visual verification.

## Guardrails

- The deterministic verifier remains the only mutation authority.
- Captured evidence is immutable and never presented as a live notebook connection.
- The current public CPU fallback remains explicitly labeled.
- Candidate rationale is limited to structured actions and verifier outcomes.
