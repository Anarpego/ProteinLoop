# Feature Spec: Gemma Endpoint Verification

## Goal

Add an executable gate that proves the selected local or remote OpenAI-compatible Gemma endpoint is usable by ProteinLoop before final submission. Spec 050 makes local evidence the selected final profile when hosted credentials are unavailable.

## User Value

The team can verify the model boundary from the command line: `/v1/models` is reachable and `/v1/chat/completions` returns a valid simulator action that the deterministic harness can evaluate.

## Functional Requirements

1. The repo shall include a stdlib-only Gemma endpoint validator.
2. The validator shall accept `GEMMA_ENDPOINT`, `GEMMA_MODEL`, and optional `GEMMA_API_KEY`.
3. The validator shall verify `GET /v1/models` returns a successful OpenAI-compatible response.
4. The validator shall verify `POST /v1/chat/completions` returns a parseable ProteinLoop action JSON object.
5. The validator shall reject missing action fields and non-numeric action values.
6. The validator shall write a small evidence JSON artifact on success.
7. The repo shall expose the validator through a Make target.
8. Documentation shall show how to run the validator after starting the AMD ROCm vLLM profile.
9. Final readiness shall reject Gemma evidence that is not for a Gemma 4 model.
10. Final readiness shall reject localhost Gemma evidence for the final submission gate.

## Acceptance Criteria

1. Unit tests cover action parsing, URL construction, and validation failures without network access.
2. `make gemma-check` reports a clear configuration failure when `GEMMA_ENDPOINT` is missing.
3. The command can be used against a live endpoint to produce `submission/gemma-evidence.json`.
