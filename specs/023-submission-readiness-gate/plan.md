# Implementation Plan: Submission Readiness Gate

## Scope

- Add `scripts/validate_submission_readiness.py`.
- Keep the validator dependency-free.
- Add focused unit tests for parsing and URL normalization.
- Add `make submission-ready-check`.
- Document the final gate in README.

## Verification

- Run `python3 -m unittest tests.test_submission_readiness`.
- Run `make submission-ready-check` and record any remaining external failures.
- Run `make test` to include the new tests.
