# Public Deployment Evidence

- Checked: `2026-07-11T05:53:21Z`
- URL: `https://proteinloop.dev-vb.lat`
- Commit: `4feca8f1549e0511aee9807a00409a20bf061d3c`
- Compose project: `proteinloop`
- Phoenix bind: `127.0.0.1:4011`, proxied by Caddy with HTTPS
- Simulator: private on the Compose network
- Public Gemma status: `Gemma 4 endpoint configured`
- Gemma runtime: private llama.cpp CPU service, `google/gemma-4-E2B-it`, no host port
- Host after inference: 7.8 GiB RAM total, 5.3 GiB available, 138 GiB disk available

`make live-demo-check` passed the operator route, truthful Gemma status, English producer route,
12,488,144-byte PBR fish model, and 151,238-byte realistic prawn visual. The three pre-existing
Kato containers remained active after deployment. The private endpoint advertised the expected
model and returned a structured action inside the deterministic safety envelope; the machine-readable
proof is `submission/cpu-gemma-deployment-evidence.json`. The public CPU host intentionally does not
claim AMD-hosted or GPU inference.
