# ProteinLoop AMD-Hosted Gemma Evidence

Captured on the assigned Act-II AMD notebook on July 12, 2026 UTC. This is immutable experiment
evidence, not a claim that the temporary notebook endpoint remains connected to the public demo.

## Runtime

- Model: `google/gemma-4-E2B-it`
- Python: `3.12.13`
- PyTorch: `2.10.0+git8514f05`
- ROCm: `7.2.53211`
- vLLM: `0.20.2rc1.dev15+g321fa2d6d`
- AMD GPU architecture: `gfx1100`, 96 compute units
- GPU memory: 47.98 GiB GDDR6
- GPU tensor test: passed in 320.237 ms
- Structured endpoint action contract: passed

## Verifier-Guided Search

Gemma generated six recovery candidates for the same ammonia/oxygen emergency. ProteinLoop also
injected one deliberately unsafe control.

- Safe candidates admitted: 3
- Candidates rejected before mutation: 4
- Unsafe control executed: no
- Selected source: AMD-hosted Gemma
- Selected strategy: oxygen-first emergency recovery
- Selected action: 0 kg feed, 8 hours aeration, 25% water exchange, 0 kg duckweed harvest
- Ammonia: 2.4 -> 0.7228 mg/L
- Dissolved oxygen: 4.8 -> 5.6742 mg/L
- Selected reward: 313.3456
- Reward improvement over naive routine: +71.092
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
- Median generation latency across 30 requests: 644.384 ms
- p95 generation latency: 714.654 ms

The fallback result is deliberate product behavior. When every Gemma proposal violates a domain
rule, the system records that the model supplied no admissible plan and uses the existing verified
emergency policy. It never relabels deterministic fallback output as model output.

## Twenty-Emergency Verifier-Feedback Audit

The final experiment expanded the five emergency families into 20 deterministic operating
conditions. Each rejected action returned exact violations, limits, warnings, and current state to
Gemma for at most three fresh revisions. Every revision passed through the same parser and verifier.

- First answer safe: 2/20 (10%)
- Safe after verifier-feedback repair: 20/20 (100%)
- Rejected first answers repaired: 18
- Repaired in one revision: 17
- Repaired in two revisions: 1
- Independent best-of-six safe: 9/20 (45%)
- Combined model path safe: 20/20 (100%)
- Deterministic fallbacks used: 0
- Deliberate unsafe controls rejected: 20/20
- Aggregate aquatic biomass represented across scenarios: 420.648 kg
- Mean reward delta versus naive: +221.7244
- Model requests: 139
- Observed token usage: 51,211 prompt + 9,174 completion = 60,385 total
- Median client-observed latency: 655.522 ms; p95: 729.105 ms
- Observed completion throughput: 99.793 tokens/s
- Generation errors: 0

This was inference-time structured repair. No training, fine-tuning, reinforcement-learning update,
or model weight change occurred. Throughput is client-observed completion throughput, not a server
benchmark. Biomass is summed over deterministic test scenarios, not farm production.

## Artifact Integrity

- `amd-notebook-gemma-evidence.json`: `f37866fe6daa9b343fba015645aefe8959878d3ebd8dda221ef8fa5f3daef73e`
- `amd-gemma-policy-search.json`: `76a527b9c012242e413adcd65495e97c69630a766b9b9421db172c5fde58ecfd`
- `amd-gemma-product-evaluation.json`: `dd1d89487673785e73213dd57460aa275704814596dd095e51d4f11f92feb331`
- `amd-gemma-repair-evaluation.json`: `0436af257d2635a5cffc5a66de394784d8f5ce0f8cb72a02ec9e72313c47e5d0`
- `amd-notebook-freeze.txt`: `8b5c0068ad805174e93b5f7c4f21dc15628b9815045a48ca881920dae1e21e70`
- `ProteinLoop_AMD_Gemma_Verifier_Repair.ipynb`: `cf13bfb5e9610268937c5aad8fe9b60d1988356f4b67b7dd1b43db55c501dc64`

The validated round-trip ZIP SHA-256 was
`b8e6a62e050d5f85dc6aadabd40da2c3f7197afc4a7d46afa4bbed8a7f0f67b3`, sourced from commit
`a4b67d80659b4b92f863f1a508cd1b58e2a95b36`.

The artifacts contain no Hugging Face token, endpoint key, cookie, UUID, hardware serial number,
or private chain-of-thought.
