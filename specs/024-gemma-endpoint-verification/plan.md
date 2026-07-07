# Implementation Plan: Gemma Endpoint Verification

## Scope

- Add `scripts/validate_gemma_endpoint.py`.
- Keep the validator dependency-free with `urllib`.
- Add unit tests for pure parsing and validation behavior.
- Add `make gemma-check`.
- Update the AMD deployment runbook and README.

## Verification

- Run `python3 -m unittest tests.test_gemma_endpoint_validator`.
- Run `make gemma-check` without `GEMMA_ENDPOINT` and confirm it fails with a configuration error.
- Run `make test`.
- Run existing CI/submission validators.
