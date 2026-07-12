# ProteinLoop Final Readiness Report

Generated: 2026-07-12T06:34:31+00:00
Commit: `46f5340`
Working tree (source): `clean`
Gemma evidence mode: `amd_notebook`

## Command Evidence

| Gate | Command | Exit | Status |
| --- | --- | ---: | --- |
| Unit tests | `make test` | 0 | PASS |
| Submission artifacts | `make submission-check` | 0 | PASS |
| Docker smoke | `make docker-smoke` | 0 | PASS |
| Real Sagents evidence | `make sagents-evidence` | 0 | PASS |
| Real Horde failover evidence | `make horde-evidence` | 0 | PASS |
| Live nRF9151 DECT NR+ evidence | `make nrf9151-live-evidence` | 0 | PASS |
| CI workflow contract | `make ci-check` | 0 | PASS |
| Public deploy profile | `make public-deploy-check` | 0 | PASS |
| AMD notebook Gemma evidence | `make amd-notebook-gemma-evidence` | 0 | PASS |
| AMD Gemma verifier-guided search | `make amd-notebook-gemma-search` | 0 | PASS |
| AMD Gemma five-emergency product audit | `make amd-notebook-product-eval` | 0 | PASS |
| AMD Gemma verifier-feedback repair audit | `make amd-notebook-repair-eval` | 0 | PASS |
| Public demo environment | `make public-env-check` | 0 | PASS |
| Public live demo | `make live-demo-check` | 0 | PASS |
| Final submission readiness | `make submission-ready-check` | 0 | PASS |

## Remaining Blockers

- None. Final readiness gates are passing.

## Next Commands

```sh
PHX_HOST=your-demo-host SECRET_KEY_BASE=$(cd app && mix phx.gen.secret) make public-env-check
DEMO_URL=https://your-public-demo-url make live-demo-check
make set-demo-url DEMO_URL=https://your-public-demo-url
AMD_NOTEBOOK_STATUS=active make credit-check
make amd-notebook-gemma-evidence GEMMA_MODEL=google/gemma-4-E2B-it
make sagents-evidence
SUBMISSION_GEMMA_MODE=amd_notebook make submission-finalize
```

## Output Snippets

### Unit tests

```text
python3 -m unittest discover -s tests
............................................................................................................................................................................................................................
----------------------------------------------------------------------
Ran 220 tests in 0.198s

OK
```

### Submission artifacts

```text
python3 scripts/validate_visual_evidence.py
[ok] operator-desktop.png 1440x1200 variance=3156.613
[ok] operator-mobile.png 390x844
[ok] producer-desktop.png 1440x1200 variance=1450.814
[ok] producer-mobile.png 390x844
[ok] tank-fullscreen-desktop.png 1440x1200 variance=3899.385
[ok] tank-fullscreen-mobile.png 390x844 variance=1669.175
wrote submission/visual-evidence/report.json
python3 scripts/validate_submission_artifacts.py
submission artifacts OK
pptx slides: 10
pdf pages: 10
```

### Docker smoke

```text
evidence: submission/docker-smoke-evidence.json
checked_at: 2026-07-11T17:09:37.494355+00:00
[ok] simulator health
[ok] anomaly forecast endpoint
[ok] rlvr endpoint
[ok] rlvr training endpoint
[ok] reset endpoint
[ok] ammonia spike endpoint
[ok] safety recovery endpoint - reward=135.2741
[ok] guided operator control route
[ok] producer English route
[ok] producer tank remains read-only
[ok] bundled PBR fish model - bytes=12488144
[ok] bundled realistic prawn visual - bytes=151238
docker smoke OK
```

### Real Sagents evidence

```text
evidence: submission/sagents-evidence.json
Sagents 0.9.0
model: google/gemma-4-E2B-it
[ok] action_preserved
[ok] custom_safety_mode
[ok] four_subagents_completed
[ok] hitl_interrupted_before_mutation
[ok] hitl_reject_resumed_without_mutation
[ok] real_sagents_runtime
[ok] real_sagents_subagents
[ok] until_tool_success
[ok] verification_accepted
real Sagents evidence OK
```

### Real Horde failover evidence

```text
evidence: submission/horde-evidence.json
Sagents 0.9.0
Horde 0.10.0
membership: participation
[ok] actual_owner_service_stopped
[ok] managed_agent_identity_preserved
[ok] managed_agent_registered_before
[ok] owner_node_changed
[ok] real_horde_distribution
[ok] state_fingerprint_preserved
[ok] state_persisted_before_failover
[ok] state_restored_on_survivor
[ok] state_token_preserved
[ok] stopped_node_rejoined
[ok] two_nodes_connected_before
real Horde failover evidence OK
```

### Live nRF9151 DECT NR+ evidence

```text
evidence: submission/nrf9151-live-evidence.json
2 physical boards
installed NCS: 3.3.1
latest researched NCS: 3.4.0
[ok] bidirectional_peer_consistency
[ok] both_serial_ports_opened
[ok] both_serial_ports_present
[ok] ft_role_confirmed
[ok] ft_sent_and_received
[ok] live_serial_not_simulated
[ok] pt_role_confirmed
[ok] pt_sent_and_received
live two-board DECT NR+ evidence OK
```

### CI workflow contract

```text
python3 scripts/validate_ci_workflow.py
ci workflow OK
```

### Public deploy profile

```text
python3 scripts/validate_public_deploy.py
[ok] public compose file
[ok] required public compose settings
[ok] local-only settings absent
[ok] simulator not publicly published
public deploy profile OK
```

### AMD notebook Gemma evidence

```text
evidence: submission/amd-notebook-gemma-evidence.json
[ok] google/gemma-4-E2B-it on ROCm 7.2.53211 / gfx1100
```

### AMD Gemma verifier-guided search

```text
evidence: submission/amd-gemma-policy-search.json
[ok] 6 Gemma candidates; 3 safe; +71.0920 vs naive
```

### AMD Gemma five-emergency product audit

```text
evidence: submission/amd-gemma-product-evaluation.json
[ok] 5 emergencies; 100% safe final plans; 103.1 kg protected
```

### AMD Gemma verifier-feedback repair audit

```text
evidence: submission/amd-gemma-repair-evaluation.json
[ok] 20 emergencies; 18 repair rescues; 100% model-safe
```

### Public demo environment

```text
python3 scripts/validate_public_env.py
[ok] PHX_HOST - proteinloop.dev-vb.lat
[ok] SECRET_KEY_BASE - 128 characters
[ok] PUBLIC_PORT - 4011
[ok] SIMULATOR_URL - http://simulator:8000
public environment OK
```

### Public live demo

```text
DEMO_URL="https://proteinloop.dev-vb.lat" SIMULATOR_PUBLIC_URL="" python3 scripts/validate_live_demo.py
[ok] guided operator control route
[ok] Gemma endpoint status - Gemma 4 endpoint configured
[ok] producer English route
[ok] bundled PBR fish model - bytes=12488144
[ok] bundled realistic prawn visual - bytes=151238
live demo OK
```

### Final submission readiness

```text
SUBMISSION_GEMMA_MODE="amd_notebook" python3 scripts/validate_submission_readiness.py
[ok] required local artifacts
[ok] lablab form matches draft - submission/lablab-form.json
[ok] submission bundle contents - submission/proteinloop-lablab-upload.zip
[ok] AMD notebook Gemma evidence - google/gemma-4-E2B-it on ROCm 7.2.53211 / gfx1100
[ok] AMD Gemma verifier-guided search - 6 Gemma candidates; 3 safe; +71.0920 vs naive
[ok] AMD Gemma five-emergency product audit - 5 emergencies; 100% safe final plans; 103.1 kg protected
[ok] AMD Gemma verifier-feedback repair audit - 20 emergencies; 18 repair rescues; 100% model-safe
[ok] public GitHub repository URL - https://github.com/Anarpego/ProteinLoop
[ok] application URL - https://proteinloop.dev-vb.lat
[ok] public GitHub repository reachable - https://github.com/Anarpego/ProteinLoop
[ok] application control reachable - https://proteinloop.dev-vb.lat
[ok] application producer route reachable - https://proteinloop.dev-vb.lat/producer
[ok] local git repository
[ok] local git commit - 46f5340bc7ddeb9488358c2d5f6a706a910c97c2
[ok] origin remote configured - git@github.com:Anarpego/ProteinLoop.git
[ok] origin matches lablab repository URL - origin=git@github.com:Anarpego/ProteinLoop.git lablab=https://github.com/Anarpego/ProteinLoop
submission readiness OK
```
