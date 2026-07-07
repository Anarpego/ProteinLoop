# Implementation Plan: AMD Gemma vLLM Deployment Profile

## Scope

- Add `.env.example` with local simulator/web/Gemma variables.
- Add `docker-compose.gemma-rocm.yml` behind an `amd-gemma` profile.
- Add `deploy/amd-gemma-vllm.md` with commands and verification steps.
- Keep the main `docker-compose.yml` unchanged so local demo startup remains simple.

## Research Notes

- Hex/GitHub research in the previous slice confirmed Sagents latest as `0.9.0`.
- vLLM Gemma 4 official docs list `vllm/vllm-openai-rocm:gemma4` for AMD GPUs and AMD deployment flags using `/dev/kfd`, `/dev/dri`, host IPC/networking, and ROCm privileges.
- The docs note the historical recipe page now points to `recipes.vllm.ai` for freshest interactive commands.

## Verification

- Validate the AMD-only compose file with `docker compose ... --profile amd-gemma config`.
- Run `mix format --check-formatted`, `mix test`, and `make test`.
- Do not try to run the ROCm container on non-AMD hardware.
