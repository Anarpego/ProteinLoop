# Feature Spec: Submission Readiness Hardening

## Goal

Prevent the final submission readiness gate from passing with local-only demo URLs or an incomplete upload artifact set.

## User Value

The team can trust `make submission-ready-check` as the final lablab gate instead of accidentally submitting a localhost demo URL or a partial artifact packet.

## Functional Requirements

1. The readiness validator shall reject localhost, loopback, and private-network application URLs for final submission.
2. The readiness validator shall keep allowing only GitHub-hosted public repository URLs for the repo field.
3. The readiness validator shall require the generated upload bundle and manifest.
4. The readiness validator shall require the generated video, deck, cover, demo evidence, rehearsal evidence, mesh evidence, nRF9151 evidence, lablab form export, and final readiness report.
5. Unit tests shall cover localhost and private application URL rejection.
6. Unit tests shall cover the expanded local artifact list.

## Acceptance Criteria

1. `python3 -m unittest tests.test_submission_readiness` passes.
2. `make submission-ready-check` still fails clearly on real external blockers when public URLs and Gemma evidence are missing.
3. `make test` passes.
