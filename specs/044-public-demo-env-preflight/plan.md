# Implementation Plan: Public Demo Environment Preflight

## Scope

- Add `scripts/validate_public_env.py`.
- Add focused Python unit tests.
- Add `make public-env-check`.
- Update README and `deploy/live-demo.md`.
- Keep the existing `make public-deploy-check` Compose-structure gate unchanged.

## Verification

- Run `python3 -m unittest tests.test_public_env_validator`.
- Run `make public-env-check` without env and confirm it fails clearly.
- Run `make test`.
- Run `make submission-check`.
