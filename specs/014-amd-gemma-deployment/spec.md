# Feature Spec: AMD Gemma vLLM Deployment Profile

## Goal

Prepare the repo for AMD-hosted Gemma deployment through vLLM/ROCm while preserving the existing OpenAI-compatible `GEMMA_ENDPOINT` boundary.

## User Value

The project can be run locally with deterministic stubs, then pointed at an AMD Developer Cloud Gemma server without code changes. Judges can inspect concrete deployment commands and environment variables for the Best AMD-Hosted Gemma story.

## Functional Requirements

1. The repo shall include an example environment file documenting `GEMMA_ENDPOINT`, `GEMMA_MODEL`, and optional auth.
2. The repo shall include an AMD ROCm vLLM Docker Compose profile using the current `vllm/vllm-openai-rocm:gemma4` image.
3. The deployment docs shall explain how to start the Gemma server, probe `/v1/models`, and point the Phoenix app at it.
4. The deployment docs shall cite the official vLLM Gemma 4 and AMD ROCm references used for the command shape.
5. Local validation shall prove the Compose profile is syntactically valid without requiring AMD hardware.

## Acceptance Criteria

1. `docker compose -f docker-compose.gemma-rocm.yml --profile amd-gemma config` succeeds locally.
2. README links the AMD Gemma deployment profile.
3. Existing Python and Phoenix regression tests still pass.
4. The spec task checklist is complete except for actual AMD GPU runtime, which remains explicitly external.
