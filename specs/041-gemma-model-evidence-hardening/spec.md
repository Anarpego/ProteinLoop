# Feature Spec: Gemma Model Evidence Hardening

## Goal

Require Gemma endpoint evidence to prove the requested Gemma 4 model is actually advertised by the OpenAI-compatible `/v1/models` response.

## User Value

The final submission can demonstrate that ProteinLoop is configured against a real Gemma 4 model endpoint, not just any OpenAI-compatible server paired with a manually typed model id.

## Functional Requirements

1. The Gemma endpoint validator shall check that the requested model appears in `/v1/models`.
2. The validator shall include the advertised model ids in `submission/gemma-evidence.json`.
3. The validator shall fail before writing evidence when the requested model is missing from `/v1/models`.
4. Final submission readiness shall reject Gemma evidence whose `models` list does not include the claimed `model`.
5. Unit tests shall cover advertised-model matching and mismatch rejection.

## Acceptance Criteria

1. `python3 -m unittest tests.test_gemma_endpoint_validator tests.test_submission_readiness` passes.
2. `make gemma-check` still reports a clear configuration error when `GEMMA_ENDPOINT` is missing.
3. `make test` passes.
