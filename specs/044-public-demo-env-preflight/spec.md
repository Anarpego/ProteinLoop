# Feature Spec: Public Demo Environment Preflight

## Goal

Add an executable preflight that validates production environment values before starting the public demo Compose profile.

## User Value

The team can catch common public demo deployment mistakes before submitting a broken Application URL to lablab.

## Functional Requirements

1. The repo shall include a stdlib-only public demo environment validator.
2. The validator shall require `PHX_HOST` to be a public hostname, not localhost, loopback, or a private IP.
3. The validator shall require `SECRET_KEY_BASE` to be present, not a placeholder, and at least 64 characters.
4. The validator shall accept `PUBLIC_PORT` only when it is an integer from 1 through 65535.
5. The validator shall verify `SIMULATOR_URL` defaults to or equals `http://simulator:8000`.
6. The validator shall expose clear failure messages and return non-zero when required values are unsafe.
7. The repo shall expose the validator through a Make target and document it in README and the live-demo runbook.

## Acceptance Criteria

1. Unit tests cover host classification, secret validation, port validation, and simulator URL validation.
2. `make public-env-check` fails clearly with missing environment values.
3. `make test` passes.
