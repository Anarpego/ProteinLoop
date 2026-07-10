# Implementation Plan: Local Gemma 4 Inference

## Research Basis

- Google lists Gemma 4 E2B as the smallest Gemma 4 architecture.
- Google's official memory table estimates 2.9 GB for Gemma 4 E2B Q4 weights, making it the lowest-memory Gemma 4 choice for the development Mac.
- Google's official QAT collection provides `google/gemma-4-E2B-it-qat-q4_0-gguf` for llama.cpp and names `google/gemma-4-E2B-it` as the instruction model.
- llama.cpp is optimized for Apple Silicon and exposes an OpenAI-compatible server. Release `b9946` is the latest release verified on July 9, 2026.
- vLLM `0.23.0` adds Gemma 4 Unified support and is the vLLM quick-start version shown by AMD Developer Cloud.

## Scope

- Add a stdlib-only local runtime manager with checksum-verified installation and lifecycle commands.
- Add unit tests before runtime implementation.
- Add Make targets and ignore local model/runtime artifacts.
- Update local and AMD defaults to Gemma 4 E2B IT.
- Document the local-to-AMD workflow.
- Download and run the model, then verify the real endpoint and harness.

## Verification

- Run the focused local manager and Gemma validator tests.
- Install and start the actual local model server.
- Run `make local-gemma-check` and a real Phoenix harness call.
- Run full Python and Phoenix tests.
- Validate both local and AMD Compose profiles and submission gates.
