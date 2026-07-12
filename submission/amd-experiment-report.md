# ProteinLoop AMD-Hosted Gemma Evidence

Captured on the assigned Act-II AMD notebook on July 11, 2026. This is immutable experiment
evidence, not a claim that the temporary notebook endpoint remains connected to the public demo.

## Runtime

- Model: `google/gemma-4-E2B-it`
- Python: `3.12.13`
- PyTorch: `2.10.0+git8514f05`
- ROCm: `7.2.53211`
- vLLM: `0.20.2rc1.dev15+g321fa2d6d`
- AMD GPU architecture: `gfx1100`, 96 compute units
- GPU memory: 47.98 GiB GDDR6
- GPU tensor test: passed in 494.447 ms
- Structured endpoint action contract: passed

## Verifier-Guided Search

Gemma generated six recovery candidates for the same ammonia/oxygen emergency. ProteinLoop also
injected one deliberately unsafe control.

- Safe candidates admitted: 3
- Candidates rejected before mutation: 4
- Unsafe control executed: no
- Selected source: AMD-hosted Gemma
- Selected strategy: oxygen-first emergency recovery
- Selected action: 0 kg feed, 8 hours aeration, 20% water exchange, 0 kg duckweed harvest
- Ammonia: 2.4 -> 0.85 mg/L
- Dissolved oxygen: 4.8 -> 5.5058 mg/L
- Selected reward: 311.6147
- Reward improvement over naive routine: +69.3611
- Model weight updates: none; this was inference-time verifier-guided search

## Five-Emergency Product Audit

The second experiment evaluated 30 Gemma proposals across five deterministic emergencies.

- First model answer safe: 1/5 (20%)
- Safe final plan after verification: 5/5 (100%)
- Rejected first answers rescued: 4
- Scenarios with at least one safe Gemma plan: 2/5
- Scenarios requiring the labeled deterministic fallback: 3/5
- Deliberate unsafe controls rejected: 5/5
- Aggregate aquatic biomass protected across scenarios: 103.1 kg
- Mean reward delta versus naive where comparable: +180.3907
- Median generation latency across 30 requests: 654.344 ms
- p95 generation latency: 716.535 ms

The fallback result is deliberate product behavior. When every Gemma proposal violates a domain
rule, the system records that the model supplied no admissible plan and uses the existing verified
emergency policy. It never relabels deterministic fallback output as model output.

## Artifact Integrity

- `amd-notebook-gemma-evidence.json`: `bcc64c42532494c7cad860ad56457da97f7909e496b2c4786c88590ef83bd7ff`
- `amd-gemma-policy-search.json`: `3c4b87ac6514d6053930a80edaf547e6832e7c08121db6c0f2cbd3464c8b1524`
- `amd-gemma-product-evaluation.json`: `9b6a9f4ba798c27e6989c2dce9511f76abe9528af58434634bec2c4860d02d89`

The artifacts contain no Hugging Face token, endpoint key, cookie, UUID, hardware serial number,
or private chain-of-thought.
