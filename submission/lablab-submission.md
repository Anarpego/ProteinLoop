# ProteinLoop lablab Submission Draft

## Project Title

ProteinLoop

## Short Description

An off-grid-ready protein loop using private DECT NR+, self-hosted Gemma 4, deterministic verification, and producer approval to protect fish, prawns, plants, duckweed, and eggs without relying on Wi-Fi or cloud access.

## Long Description

ProteinLoop addresses a practical food-security gap: aquaponics connects aquatic animals and plants, but safely operating the full animal-protein outcome remains difficult. ProteinLoop makes fish and freshwater-prawn biomass measurable and recoverable, then extends the loop through plants that clean the water, duckweed that becomes feed, and laying chickens that produce eggs. The live interface explains ammonia as waste in the water and dissolved oxygen as air the animals can breathe, so a producer can understand the risk before reading technical values.

The simulator is the verifier. Four concurrent Sagents specialists evaluate fish, prawns, plants, and the feed loop; a supervisor synthesizes one bounded proposal. Gemma can recommend aeration, feed, water exchange, or harvest actions, but deterministic ecosystem rules are the only authority allowed to mutate state. Judges can inject an ammonia emergency, watch structured agent events in real time, see an unsafe proposal rejected before mutation, execute a verified recovery, and inspect measured chemistry before and after. The same Dockerized application includes RLVR policy comparison, anomaly forecasting, a real two-node Horde state-restoration proof, and producer approval that can approve, reduce, or reject risky actions.

Two physical nRF9151 boards prove a bidirectional DECT NR+ field link between tank and gateway without Wi-Fi, a SIM, or cloud access. A separate edge computer runs the smallest Gemma 4 instruction model, `google/gemma-4-E2B-it`, through the OpenAI-compatible `GEMMA_ENDPOINT`; Gemma does not run on the radio boards. The public demo self-hosts llama.cpp on an owned 8 GB CPU server; Apple Metal evidence proves the full workflow. The repository includes a portable ROCm/vLLM deployment profile but does not claim current AMD-hosted GPU inference. Chemistry probes, measured solar autonomy, field range, and regional approval remain the next proofs.

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

The competition's AMD notebook service was unavailable and no AMD Developer Cloud or Fireworks credits were issued to this team before the deadline. The submitted demo therefore uses owned infrastructure: self-hosted Gemma 4 E2B through llama.cpp on an 8 GB DigitalOcean CPU host, plus separate Apple Metal evidence. The repository includes a tested AMD ROCm/vLLM deployment profile behind the same `GEMMA_ENDPOINT`, but does not misrepresent the current demo as AMD-hosted or GPU-backed.

Physical evidence comes from two real nRF9151 boards exchanging bidirectional DECT NR+ sequence 100. This proves the private no-Wi-Fi field link; chemistry probes and measured solar autonomy remain explicit next deployment proofs. Deterministic ecosystem rules, not the LLM, retain mutation authority, and risky actions pause for producer approval.

## Key Demo Path

1. Open the operator route and read the animated fish-to-eggs loop, executable proof ribbon, and `Off-grid continuity` band. The band explains no-Wi-Fi DECT NR+, no-cloud self-hosted Gemma, the planned solar-plus-battery power layer, and the proven-versus-planned acquisition path.
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
- Product potential: resilient protein production for rural Latin America where farm Wi-Fi, cloud access, and grid electricity cannot be assumed; solar autonomy and physical chemistry probes remain measured deployment milestones.
- Completeness: simulator, dashboard, harness, traces, physical radio evidence, Docker, deployment profile, submission artifacts.
- Model evidence: live public CPU and local Metal Gemma 4 E2B inference through llama.cpp; the portable ROCm/vLLM profile is documented as an optional future host, not a submitted deployment claim.
- Public deployment: the HTTPS judge demo runs Phoenix, the private simulator, and private Gemma 4 E2B on an owned 8 GB CPU DigitalOcean host. The model has no host port and every proposal still passes through the deterministic verifier; this is not presented as AMD/GPU inference.
