# Implementation Plan: Submission Readiness Hardening

## Scope

- Add URL host classification helpers to `scripts/validate_submission_readiness.py`.
- Apply public-host validation to the application URL field.
- Expand `REQUIRED_ARTIFACTS` to match the generated lablab upload packet.
- Add focused stdlib unit tests.
- Update README to document that localhost/local-network app URLs are not accepted for final readiness.

## Verification

- Run `python3 -m unittest tests.test_submission_readiness`.
- Run `make submission-ready-check`.
- Run `make test`.
- Run `make submission-check`.
