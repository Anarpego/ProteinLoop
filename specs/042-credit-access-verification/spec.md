# Feature Spec: Credit Access Verification

## Goal

Add an executable helper that verifies the hackathon credit prerequisites before attempting the final Gemma endpoint gate.

## User Value

The team can quickly distinguish missing API credentials, inactive AMD Cloud access, and a real model-endpoint problem before spending time on deployment.

## Functional Requirements

1. The repo shall include a stdlib-only credit access validator.
2. The validator shall accept `FIREWORKS_API_KEY` and optional `FIREWORKS_BASE_URL`.
3. The validator shall verify Fireworks API access by calling an OpenAI-compatible `/models` endpoint.
4. The validator shall require an explicit AMD Cloud status marker, `AMD_CLOUD_STATUS=active`, before reporting full credit readiness.
5. The validator shall produce clear failure messages when Fireworks credentials or AMD Cloud confirmation are missing.
6. The repo shall expose the helper through a Make target.
7. README shall document the exact credit verification commands before `make gemma-check`.

## Acceptance Criteria

1. Unit tests cover missing Fireworks key, model-list parsing, and AMD status handling without network access.
2. `make credit-check` reports a clear configuration failure when credentials/status are missing.
3. `make test` passes.
