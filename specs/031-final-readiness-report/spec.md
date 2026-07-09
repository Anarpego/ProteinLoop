# Feature Spec: Final Readiness Report

## Goal

Generate a shareable final readiness report that records current executable evidence, unresolved external gates, and the exact commands needed before lablab upload.

## User Value

The team can hand off or resume the final submission process without guessing which parts are locally complete and which still require external credentials, public URLs, or a live Gemma endpoint.

## Functional Requirements

1. The repo shall include a stdlib-only readiness report generator.
2. The generator shall write `submission/final-readiness-report.md`.
3. The report shall include the current git commit, working tree status, generated timestamp, command evidence, remaining blockers, and next commands.
4. The command evidence shall capture exit codes for local tests, submission artifact validation, Docker smoke validation, CI workflow contract validation, public deploy profile validation, credit access validation, public demo environment validation, Gemma endpoint validation, final submission readiness, and GitHub CLI authentication.
5. The generator shall not fail just because external gates fail; external failures must be visible in the report.
6. The report shall keep the Gemma command aligned to Gemma 4 through `GEMMA_ENDPOINT` and `GEMMA_MODEL`.

## Acceptance Criteria

1. `make readiness-report` writes `submission/final-readiness-report.md`.
2. Unit tests cover blocker extraction and report rendering.
3. `make test` passes.
4. `make readiness-report` completes even when final external readiness is still failing.
