# Public Deployment Evidence

- Checked: `2026-07-11T04:55:53Z`
- URL: `https://proteinloop.dev-vb.lat`
- Commit: `c15a1c957c9a3889fe09608d73e9ecf4c2fee930`
- Compose project: `proteinloop`
- Phoenix bind: `127.0.0.1:4011`, proxied by Caddy with HTTPS
- Simulator: private on the Compose network
- Public Gemma status: `Gemma 4 endpoint unavailable`

`make live-demo-check` passed the operator route, truthful Gemma status, English producer route,
12,488,144-byte PBR fish model, and 151,238-byte realistic prawn visual. The three pre-existing
Kato containers remained active after deployment. The public CPU host intentionally does not claim
AMD-hosted inference; `submission/local-gemma-evidence.json` records the proven self-hosted Gemma
profile separately.
