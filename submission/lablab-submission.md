# ProteinLoop lablab Submission Draft

## Project Title

ProteinLoop

## Short Description

ProteinLoop is an off-grid aquaculture resilience platform using private DECT NR+, self-hosted Gemma 4, deterministic verification, and producer approval to protect fish and prawn biomass without depending on Wi-Fi or cloud access.

## Long Description

ProteinLoop is an off-grid resilience platform for aquaculture. FAO SOFIA 2026 reports that aquaculture produced 103 million tonnes of aquatic animals in 2024, valued at $371 billion at farm gate. Our beachhead is hard-to-connect fish and prawn farms, producer cooperatives, and food-security programs where a chemistry event can destroy living inventory before a cloud-first dashboard helps. The proposed commercial model combines edge commissioning with annual site software and support, then expands from tank to site to cooperative network.

The product makes fish and freshwater-prawn biomass measurable and recoverable while connecting plants that clean water, duckweed feed, chickens, and eggs. Its animated operator view explains ammonia as waste and dissolved oxygen as underwater air before showing technical values. Four concurrent Sagents specialists evaluate fish, prawns, plants, and feed; a supervisor proposes one bounded intervention. Gemma may recommend aeration, feeding, water exchange, or harvest, but the deterministic Python verifier alone admits mutation. Judges can inject an emergency, watch real agent events, inspect unsafe rejection, execute recovery, and see measured chemistry. Risky actions pause for producer approval, reduction, or rejection.

Two physical nRF9151 boards prove a bidirectional DECT NR+ field link without Wi-Fi, a SIM, or cloud access; Gemma runs on separate compute. On the assigned Act-II AMD notebook, Gemma 4 E2B ran through vLLM on ROCm with 47.98 GiB GPU memory. In a 20-emergency audit, only 2 first answers were safe. Exact verifier feedback repaired the other 18, yielding 20/20 model-safe plans with zero fallback and no weight update. The run observed 139 requests, 60,385 tokens, and 420.648 kg of aggregate scenario biomass. The public demo remains a private CPU deployment and labels AMD results as captured evidence. Physical probes and measured solar autonomy remain next proofs.

## Categories

- Climate
- Cloud Application

## Technology Tags

- Gemma
- llama.cpp
- Apple Metal
- vLLM
- Elixir
- Phoenix LiveView
- Python
- Multi-agent systems
- Horde
- Human-in-the-loop
- DECT NR+
- Edge AI
- Off-grid systems
- RLVR
- Docker
- Food security

## Repository

Public GitHub Repository: https://github.com/Anarpego/ProteinLoop

## Demo Application Platform

Docker Compose

## Application URL

https://proteinloop.dev-vb.lat

## Docker Image

N/A

## Additional Information

ProteinLoop is a Track 3 Unicorn submission, so the Track 1/Track 2 Docker Image field is `N/A`. The project itself is fully Dockerized and reproducible with the public repository's Compose instructions. The live application runs at https://proteinloop.dev-vb.lat.

Act-II organizers assigned ProteinLoop a team Jupyter pod at `https://notebooks.amd.com/hackathon`. Executable evidence records Gemma 4 E2B on Python 3.12, PyTorch 2.10, ROCm 7.2, and vLLM 0.20 on one 47.98 GiB `gfx1100` AMD GPU. Credential-free runtime, search, five-scenario, 20-scenario repair, package-freeze, and checksum-manifest artifacts are included in the public repository and submission bundle. The public URL continues to use owned infrastructure with a private CPU Gemma fallback; the UI distinguishes that live runtime from the captured AMD experiment.

Physical evidence comes from two real nRF9151 boards exchanging bidirectional DECT NR+ sequence 100. This proves the private no-Wi-Fi field link; chemistry probes and measured solar autonomy remain explicit next deployment proofs. Deterministic ecosystem rules, not the LLM, retain mutation authority, and risky actions pause for producer approval.
Gemma does not run on the radio boards; it runs on separate edge or hosted compute behind the same OpenAI-compatible contract.

## Key Demo Path

1. Open the operator route and inspect `Captured AMD experiment`: runtime provenance, the six-plan funnel, measured recovery, the five-emergency audit, and the 20-emergency verifier-feedback audit with 18 repairs and zero fallback are visible before the advanced controls.
2. Press `Run one-click verifier proof` to reproduce the emergency, block one unsafe proposal before mutation, admit a safe recovery, and show zero unsafe actions executed with measured final chemistry.
3. Inspect `Live tank simulation` and use its expand icon: locally loaded PBR fish, four recognizable foreground prawns, physical water and glass, oxygen bubbles, water-loop plants, readable chemistry, and one-second Phoenix updates continue in full screen.
4. Press `Inject demo water emergency` and watch water color, bubble activity, animal behavior, the animated food loop, and quantified fish-and-prawn risk change together.
5. In the visible `Live agent activity` control, select `Protect protein yield` and press `Create safe recovery plan`; watch the four specialist statuses, supervisor, separate safety verifier, and measured simulator outcome update from actual runtime events.
6. Read `Recovery verified`, including chemistry before/after and zero unsafe actions executed, then inspect the structured event stream and detailed `Verified recovery receipt` below the tank.
7. Open `Advanced evidence and controls` to inspect RLVR policy-search improvement and the same `Run demo cascade` harness action. The repo also includes `submission/demo-rehearsal.md` as executable rehearsal evidence for this path.
8. Inspect the `Real Sagents/Horde cluster` status band and `submission/horde-evidence.md`, which records an actual owner-service stop, restored state on the peer, and node rejoin. Press `Simulate node loss` for the repeatable control rehearsal.
9. In `Physical DECT NR+ link`, inspect sequence `#100` and both physical FT/PT identities. Explain that PT-to-FT transport is private non-cellular 5G and that a separate edge computer runs Gemma and the verifier. Press `Replay sensor alert` to map the proven radio event into an explicitly simulated ammonia alert.
10. Press `Request producer approval`, then use the English `/producer` route to inspect the same animated tank in read-only mode, approve, apply half, or reject, and inspect the WhatsApp/SMS handoff message.
11. Inspect `submission/cpu-gemma-deployment-evidence.json`, press `Check model`, and create a safe recovery plan against the private Gemma 4 E2B service used by the public demo.

## Judging Notes

- Creativity: a state-driven PBR Three.js protein tank, operator-directed multi-agent interventions, closed protein loop, real state-preserving Horde failover, private two-board DECT NR+ field transport, self-hosted Gemma, and verifier-gated human actions.
- Product potential: FAO reports 103 million tonnes and $371 billion in 2024 aquaculture aquatic-animal production. ProteinLoop starts with hard-to-connect farms, cooperatives, and food-security programs; the proposed model combines deployment with annual site software/support and expands from tank to cooperative network.
- Completeness: simulator, dashboard, harness, traces, physical radio evidence, AMD runtime/search/product/repair evidence, deterministic fallback, Docker, deployment profile, and submission artifacts.
- Model evidence: live public CPU and local Metal inference plus a captured Act-II AMD notebook run of Gemma 4 E2B through ROCm/vLLM. Six-plan search improved reward by 71.092. In the 20-emergency audit, verifier feedback repaired 18 rejected first answers and the combined model path reached 20/20 safe plans with zero fallback; no weights were updated.
- Public deployment: the HTTPS judge demo runs Phoenix, the private simulator, and private Gemma 4 E2B on an owned 8 GB CPU DigitalOcean host. The model has no host port and every proposal still passes through the deterministic verifier; this is not presented as AMD/GPU inference.
