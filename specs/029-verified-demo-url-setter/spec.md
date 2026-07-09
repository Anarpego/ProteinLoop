# Feature Spec: Verified Demo URL Setter

## Goal

Safely update the lablab `Application URL` only after the public demo URL passes the executable live-demo checks.

## User Value

The team can avoid accidentally submitting an unreachable or wrong demo URL. The helper verifies the operator dashboard and Spanish producer route before mutating the submission draft.

## Functional Requirements

1. The repo shall include a stdlib-only helper for setting the demo URL in `submission/lablab-submission.md`.
2. The helper shall require an HTTP(S) demo URL.
3. The helper shall run the same live-demo route checks used by `make live-demo-check`.
4. The helper shall support `--dry-run`.
5. The helper shall not mutate the lablab draft when verification fails.
6. The repo shall expose the helper through a Make target.
7. README and live demo docs shall document the helper.
8. After a successful update, the helper shall regenerate `submission/lablab-form.json` from the updated lablab draft.

## Acceptance Criteria

1. Unit tests cover URL replacement and failure-before-mutation behavior without network access.
2. `make set-demo-url DEMO_URL=http://127.0.0.1:4001 DRY_RUN=1` previews the update.
3. Existing regression checks still pass.
