# Implementation Plan: Gemma Model Evidence Hardening

## Scope

- Add a pure `model_is_advertised/2` helper to the Gemma endpoint validator.
- Add a `/v1/models` requested-model check to `validate_endpoint`.
- Require the same model-list proof in final readiness.
- Update unit tests for endpoint and readiness behavior.
- Update README to describe the stricter evidence requirement.

## Verification

- Run `python3 -m unittest tests.test_gemma_endpoint_validator tests.test_submission_readiness`.
- Run `make gemma-check` without `GEMMA_ENDPOINT`.
- Run `make test`.
- Run `make submission-check`.
