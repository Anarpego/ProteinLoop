# ProteinLoop Video Script

Target length: 2-3 minutes.

## Scene 1: Problem

Show the title and closed-loop diagram.

Narration:

ProteinLoop is an agentic aquaponic system for rural protein security. Aquaponics usually gives families vegetables and a little fish. ProteinLoop closes the protein cycle with fish, prawns, duckweed, hydroponic plants, and eggs.

## Scene 2: Collapse Versus Recovery

Open `http://localhost:4001/`.

Action:

Press `Run demo cascade`.

Narration:

The Python simulator is the source of truth. A naive action after an ammonia spike collapses the ecosystem. The agent harness proposes actions, but the verifier decides what can mutate state. Unsafe overfeeding is rejected before execution; the safe recovery action stabilizes the tank.

## Scene 3: RLVR Evidence

Scroll to `RLVR reward verifier`.

Narration:

The reward function is programmatic: survival, water quality, biomass, and mortality. This panel compares a naive policy with the safety policy across fixed scenarios and shows recovered collapse cases.

## Scene 4: Self-Healing Mesh

Action:

Press `Simulate node loss`.

Narration:

The subsystem agents are modeled as an OTP-style mesh. When an edge node fails, the affected agents migrate to healthy nodes with their state tokens intact. This is the local demo version of the Horde/Sagents self-healing story.

## Scene 5: Spanish HITL

Action:

Press `Request producer approval`, open `/producer`, press `Solo mitad` or `Aprobar`.

Narration:

Risky water exchange and harvest actions pause for the producer in Spanish. The producer can approve, reject, or edit the tool call. Even after approval, the simulator verifier remains the mutation boundary.

## Scene 6: Real Sagents Runtime

Action:

Press `Run Gemma agents`.

Narration:

Sagents 0.9.0 runs four Gemma subsystem agents in parallel, then a fifth parent supervisor calls `close_cycle`. The custom `verify_ecosystem_safety` mode checks the action before execution, and `until_tool_success` returns the accepted action, verifier result, and reward.

## Scene 7: AMD Gemma

Show `deploy/amd-gemma-vllm.md` or the model status panel.

Narration:

For the AMD-hosted path, the same app points `GEMMA_ENDPOINT` at a vLLM OpenAI-compatible Gemma server running on ROCm. The repo includes the deployment profile using `vllm/vllm-openai-rocm:gemma4`.

## Closing

Narration:

ProteinLoop is a food system and an agent system at the same time: a closed protein loop controlled by a verifier-gated, human-aware, fault-tolerant agentic loop.
