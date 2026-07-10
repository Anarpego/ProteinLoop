# ProteinLoop lablab Submission Draft

## Project Title

ProteinLoop

## Short Description

An agentic aquaponic protein loop that keeps fish, prawns, duckweed, hydroponic plants, and chickens stable through a deterministic verifier, Spanish HITL approvals, and an AMD-hosted Gemma deployment path.

## Long Description

ProteinLoop tackles a practical food security problem: aquaponics often produces vegetables plus a small amount of fish, but rural families need a reliable protein cycle. ProteinLoop models a closed loop with fish, freshwater prawns, duckweed, plants, and laying chickens, then wraps that system in an agent harness.

The simulator is the verifier. Every proposed feed, aeration, water exchange, or harvest action is checked against deterministic ecosystem rules before state can mutate. The operator dashboard shows collapse-versus-recovery behavior, rejected unsafe proposals, RLVR reward comparison, verifier-guided policy search improvement, and a real Sagents 0.9.0 runtime with four concurrent `Sagents.SubAgent` workers plus a parent supervisor, a custom `verify_ecosystem_safety` mode, `until_tool_success`, and resumable Spanish HumanInTheLoop approval. A two-node Horde 0.10.0 cluster proves real owner loss and state restoration: the verifier stops the managed agent's actual owner, observes the same identity, state token, and fingerprint on the peer, then rejoins the node. A provider-free WhatsApp/SMS handoff supports low-bandwidth operation. Two physical nRF9151 DKs prove the field radio path: FT `1051223739` and PT `1051239227` each sent locally and received the peer's matching DECT NR+ sequence number in a read-only UART capture marked `simulated: false`. The separate sample JSONL bridge documents the future water-quality payload contract without claiming Nordic's stock `hello_dect` logs contain sensor telemetry.

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
- Horde
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
3. Inspect the `Real Sagents/Horde cluster` status band and `submission/horde-evidence.md`, which records an actual owner-service stop, restored state on the peer, and node rejoin. Press `Simulate node loss` for the repeatable dashboard rehearsal.
4. Inspect `submission/nrf9151-live-evidence.md`: both physical FT/PT boards show matching bidirectional DECT NR+ sequence numbers with no flash or reset. The field plan maps PT to the tank and FT to the gateway.
5. Press `Request producer approval`, then use `/producer` to approve/edit/reject in Spanish and inspect the WhatsApp/SMS handoff message.
6. Press `Run Gemma agents` to show four subsystem agents plus the parent supervisor, `verify_ecosystem_safety`, and `until_tool_success`.
7. If AMD-hosted Gemma is available, set `GEMMA_ENDPOINT`, press `Check model`, select `OpenAI-compatible`, and run the harness.

## Judging Notes

- Creativity: closed protein loop, real state-preserving Horde failover, physical two-board DECT NR+ proof, verifier-gated agents, Spanish HITL.
- Product potential: low-cost protein production for rural Latin America.
- Completeness: simulator, dashboard, harness, traces, physical radio evidence, Docker, deployment profile, submission artifacts.
- AMD platform use: vLLM/ROCm deployment profile for Gemma on AMD GPUs, with the app already wired to the OpenAI-compatible endpoint.
