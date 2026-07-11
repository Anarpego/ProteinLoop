# Feature Spec: Local Gemma 4 Inference

> The AMD Developer Cloud promotion wording is superseded by the Act-II notebook contract in
> `specs/066-official-compute-correction/spec.md`.

## Goal

Run the smallest current Gemma 4 instruction model locally on the development Mac through the same OpenAI-compatible boundary used by AMD-hosted vLLM.

## User Value

ProteinLoop model inference can be developed and demonstrated without internet after the model is downloaded. The exact same `GEMMA_ENDPOINT` and `GEMMA_MODEL` contract can then be promoted to AMD Developer Cloud without changing application code.

## Functional Requirements

1. The local runtime shall use Gemma 4 E2B IT, the smallest Gemma 4 model, in Google's official QAT Q4 GGUF format.
2. The local runtime shall use a pinned, checksum-verified llama.cpp Apple Silicon release that supports Gemma 4.
3. The local server shall bind to `127.0.0.1` by default and expose an OpenAI-compatible API on port `8001`.
4. `/v1/models` shall advertise `google/gemma-4-E2B-it`, matching `GEMMA_MODEL` used by ProteinLoop.
5. The repository shall provide install, start, status, stop, and endpoint-check commands through `make`.
6. First-run downloads, model cache, PID, and logs shall remain outside version control under `.local-gemma/`.
7. Local endpoint evidence shall be written to `outputs/local-gemma-evidence.json`, never to the final AMD evidence path.
8. The local endpoint check shall verify both `/v1/models` and a structured ProteinLoop action from `/v1/chat/completions`.
9. Documentation shall explain the local workflow, memory choice, offline behavior after download, and the AMD promotion path.
10. The AMD ROCm profile shall default to the same `google/gemma-4-E2B-it` model.

## Acceptance Criteria

1. Unit tests cover platform selection, checksum failure, server command construction, PID handling, and local evidence routing without network access.
2. `make local-gemma-install` installs the pinned llama.cpp runtime on the current Apple Silicon host.
3. `make local-gemma-start` reaches a healthy local `/v1/models` endpoint.
4. `make local-gemma-check` produces `outputs/local-gemma-evidence.json` for `google/gemma-4-E2B-it`.
5. A ProteinLoop OpenAI-compatible harness request succeeds against the live local endpoint and still passes through deterministic action validation.
6. Python, Phoenix, Compose, and submission regressions pass.
