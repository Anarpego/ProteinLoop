# Feature Spec: Final Submission Finalizer

## Goal

Add one executable finalization command that runs the required generated-artifact sequence before the hard final lablab readiness gate.

## User Value

After the public repo, public demo URL, and selected local-or-remote Gemma evidence exist, the team can run one command that refreshes Docker smoke evidence, structured lablab form fields, the upload bundle, and the final readiness report in the correct order before validating final submission readiness.

## Functional Requirements

1. The repo shall include a stdlib-only finalizer script.
2. The finalizer shall refresh Docker smoke evidence.
3. The finalizer shall regenerate `submission/lablab-form.json`.
4. The finalizer shall build the upload bundle before generating the readiness report.
5. The finalizer shall generate `submission/final-readiness-report.md`.
6. The finalizer shall rebuild the upload bundle after the readiness report so the zip includes the latest report.
7. The finalizer shall run `make submission-check`.
8. The finalizer shall run `make submission-ready-check` as the final command.
9. The finalizer shall stop on the first failing command and return that exit code.
10. The finalizer shall support a dry-run mode that prints the ordered commands without executing them.

## Acceptance Criteria

1. Unit tests verify the command order, especially that `make submission-bundle` appears after `make readiness-report`.
2. `make submission-finalize DRY_RUN=1` prints the finalization sequence.
3. Existing local regression checks still pass.
