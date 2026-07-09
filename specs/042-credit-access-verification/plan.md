# Implementation Plan: Credit Access Verification

## Scope

- Add `scripts/validate_credit_access.py`.
- Add focused Python unit tests with injected request functions.
- Add `make credit-check`.
- Update README with Fireworks and AMD Cloud verification commands.
- Keep final readiness unchanged; this helper is a preflight before `make gemma-check`.

## Verification

- Run `python3 -m unittest tests.test_credit_access_validator`.
- Run `make credit-check` with no env and confirm it fails clearly.
- Run `make test`.
- Run `make submission-check`.
