# ProteinLoop lablab Submission Draft

## Project Title

ProteinLoop

## Short Description

An agentic aquaponic protein loop that keeps fish, prawns, duckweed, hydroponic plants, and chickens stable through a deterministic verifier, Spanish HITL approvals, and an AMD-hosted Gemma deployment path.

## Long Description

ProteinLoop tackles a practical food security problem: aquaponics often produces vegetables plus a small amount of fish, but rural families need a reliable protein cycle. ProteinLoop models a closed loop with fish, freshwater prawns, duckweed, plants, and laying chickens, then wraps that system in an agent harness.

The simulator is the verifier. Every proposed feed, aeration, water exchange, or harvest action is checked against deterministic ecosystem rules before state can mutate. The operator dashboard shows collapse-versus-recovery behavior, rejected unsafe proposals, RLVR reward comparison, verifier-guided policy search improvement, and a real Sagents 0.9.0 runtime with four concurrent `Sagents.SubAgent` workers plus a parent supervisor, a custom `verify_ecosystem_safety` mode, `until_tool_success`, and resumable Spanish HumanInTheLoop approval. A provider-free WhatsApp/SMS handoff supports low-bandwidth operation. Two available nRF9151 DECT NR+ boards are documented as a non-blocking field extension: tank edge node plus community gateway, with sample JSONL telemetry bridged into simulator and dashboard events.

The model boundary is OpenAI-compatible through `GEMMA_ENDPOINT`. The repo includes a ROCm/vLLM deployment profile for AMD Developer Cloud using `vllm/vllm-openai-rocm:gemma4`, while the local demo remains runnable with deterministic stubs for judges who do not have model credentials.

## Technology Tags

- AMD Developer Cloud
- ROCm
- Gemma
- vLLM
- Elixir
- Phoenix LiveView
- Python
- Multi-agent systems
- Human-in-the-loop
- RLVR
- Docker
- Food security

## Repository

Public GitHub Repository: TODO

## Demo Application Platform

Docker Compose

## Application URL

TODO

## Key Demo Path

1. Open the operator dashboard.
2. Press `Run demo cascade` to show ammonia spike, unsafe rejection, safe recovery, and RLVR policy-search improvement. The repo also includes `submission/demo-rehearsal.md` as executable rehearsal evidence for this path.
3. Press `Simulate node loss` to show agent migration. The repo also includes `submission/mesh-evidence.md` proving state-token preservation from the Elixir mesh model, `submission/nrf9151-field-plan.md` mapping the two DECT NR+ boards to the field story, and `submission/nrf9151-telemetry-bridge.md` mapping sample board JSONL to simulator/dashboard events.
4. Press `Request producer approval`, then use `/producer` to approve/edit/reject in Spanish and inspect the WhatsApp/SMS handoff message.
5. Press `Run Gemma agents` to show four subsystem agents plus the parent supervisor, `verify_ecosystem_safety`, and `until_tool_success`.
6. If AMD-hosted Gemma is available, set `GEMMA_ENDPOINT`, press `Check model`, select `OpenAI-compatible`, and run the harness.

## Judging Notes

- Creativity: closed protein loop, visible self-healing, verifier-gated agents, Spanish HITL.
- Product potential: low-cost protein production for rural Latin America.
- Completeness: simulator, dashboard, harness, traces, Docker, deployment profile, submission artifacts.
- AMD platform use: vLLM/ROCm deployment profile for Gemma on AMD GPUs, with the app already wired to the OpenAI-compatible endpoint.
