# Feature Spec: Live Demo Verification

## Goal

Add an executable verification path for the public demo URL required by the hackathon submission.

## User Value

Before submitting, the team can prove that the public demo URL renders the operator dashboard and Spanish producer path that judges need to see, instead of relying on a manual browser check.

## Functional Requirements

1. The repo shall include a stdlib-only live demo validator.
2. The validator shall accept `DEMO_URL` or `--base-url` for the public Phoenix app.
3. The validator shall verify the operator dashboard contains the core demo controls and panels.
4. The validator shall verify the Spanish producer route contains approval and offline fallback controls.
5. The validator shall optionally verify a public simulator URL when `SIMULATOR_PUBLIC_URL` or `--simulator-url` is provided.
6. The repo shall expose the validator through a Make target.
7. README and deployment docs shall explain how to run the check for a submitted URL.

## Acceptance Criteria

1. `make live-demo-check DEMO_URL=http://127.0.0.1:4001` passes against a running local Docker stack.
2. Unit tests cover the validator contract without requiring network access.
3. README documents the live demo verification command.
