# Feature Spec: AMD Notebook Gemma Evidence

## Goal

Produce executable evidence that ProteinLoop self-hosted Gemma 4 E2B through vLLM on the Act-II AMD GPU notebook pod, even when the OpenAI-compatible endpoint is loopback-only inside that remote pod.

## User Value

Judges can distinguish the proven AMD-hosted Gemma runtime from the public CPU fallback and inspect the exact ROCm, PyTorch, vLLM, GPU, model, latency, structured action, and deterministic safety checks used by ProteinLoop.

## Functional Requirements

1. The repository shall provide a stdlib entry point that runs inside the AMD notebook's prepared Python kernel.
2. The collector shall call the existing `/v1/models` and `/v1/chat/completions` Gemma contract.
3. The collector shall directly inspect PyTorch ROCm availability, vLLM version, AMD GPU architecture, memory, and a real GPU tensor operation.
4. The collector shall write `submission/amd-notebook-gemma-evidence.json` without credentials, hardware serial numbers, cookies, or Hugging Face tokens.
5. The evidence shall identify `amd_hackathon_notebook` as the provider and include request and tensor latency.
6. Submission readiness shall support an `amd_notebook` model mode that accepts a loopback endpoint only when the AMD runtime and endpoint checks pass.
7. Local mode shall remain the default until the real notebook artifact is imported and validated.
8. The upload bundle shall include the AMD notebook evidence when it exists.

## Acceptance Criteria

1. Unit tests cover AMD SMI parsing and runtime evidence construction without AMD hardware.
2. Readiness tests accept complete AMD notebook evidence and reject a provider-only assertion without ROCm/GPU proof.
3. Existing local and remote evidence behavior remains unchanged.
4. The new Make target documents the exact command to run inside the prepared AMD notebook kernel.
5. Full Python and submission tests pass before publishing the collector.
