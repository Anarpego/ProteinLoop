# Implementation Plan: Local Gemma Submission Profile

1. Add mode-aware readiness tests before implementation.
2. Extend the local Gemma check with an explicit evidence output path.
3. Export and strictly validate a portable local evidence packet.
4. Make readiness-report and finalizer behavior mode-aware.
5. Correct all submission-facing hosted-AMD claims.
6. Regenerate video, deck, form, bundle, and readiness artifacts.
7. Run complete verification and publish the resulting commit.

## Guardrails

- Never copy a credential or bearer token into evidence.
- Never write local proof to the remote-only `submission/gemma-evidence.json` path.
- Keep the AMD ROCm deployment profile as documented optional infrastructure.
- Do not describe local Metal inference as AMD-hosted or ROCm-backed.
