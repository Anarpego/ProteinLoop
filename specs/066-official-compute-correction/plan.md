# Implementation Plan: Official Hackathon Compute Correction

1. Add failing tests for notebook-only, Fireworks-only, and unavailable access states.
2. Replace the AMD Developer Cloud marker with the AMD Hackathon notebook marker in the stdlib preflight.
3. Update Make and README commands for the official notebook URL and optional Fireworks path.
4. Correct submission-facing copy and regenerate derived form artifacts.
5. Run focused tests, artifact validation, and repository-wide claim checks.

## Guardrails

- Do not store a Fireworks coupon, API key, notebook token, or session cookie.
- Do not claim the notebook pod or Fireworks runtime was used until executable evidence proves it.
- Preserve the self-hosted local submission profile and deterministic safety boundary.
