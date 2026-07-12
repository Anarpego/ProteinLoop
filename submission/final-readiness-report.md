# ProteinLoop Final Readiness Report

Generated: 2026-07-12T19:31:30+00:00
Commit: `64ffd38`
Working tree (source): `M scripts/generate_submission_deck_v2.mjs
 M submission/artifact-build-manifest.json
 M submission/proteinloop-hackathon-deck.pdf
 M submission/proteinloop-hackathon-deck.pptx
 M submission/slides.md`
Gemma evidence mode: `local`

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
| Local Gemma endpoint evidence | `make local-gemma-submission-evidence` | 0 | PASS |
| Public demo environment | `make public-env-check` | 2 | FAIL |
| Public live demo | `make live-demo-check` | 2 | FAIL |
| Final submission readiness | `make submission-ready-check` | 2 | FAIL |

## Remaining Blockers

- Public demo environment: [FAIL] PHX_HOST - set PHX_HOST to the public hostname
- Public demo environment: [FAIL] SECRET_KEY_BASE - set SECRET_KEY_BASE with mix phx.gen.secret or equivalent
- Public live demo: exited 2
- Final submission readiness: [FAIL] public GitHub repository reachable - https://github.com/Anarpego/ProteinLoop: <urlopen error [Errno 8] nodename nor servname provided, or not known>
- Final submission readiness: [FAIL] application control reachable - https://proteinloop.dev-vb.lat: <urlopen error [Errno 8] nodename nor servname provided, or not known>
- Final submission readiness: [FAIL] application producer route reachable - https://proteinloop.dev-vb.lat/producer: <urlopen error [Errno 8] nodename nor servname provided, or not known>

## Next Commands

```sh
PHX_HOST=your-demo-host SECRET_KEY_BASE=$(cd app && mix phx.gen.secret) make public-env-check
DEMO_URL=https://your-public-demo-url make live-demo-check
make set-demo-url DEMO_URL=https://your-public-demo-url
make local-gemma-check
make local-gemma-submission-evidence
make sagents-evidence
SUBMISSION_GEMMA_MODE=local make submission-finalize
```

## Output Snippets

### Unit tests

```text
python3 -m unittest discover -s tests
..............................................................................................................................................................................................................................
----------------------------------------------------------------------
Ran 222 tests in 0.183s

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

### Local Gemma endpoint evidence

```text
evidence: submission/local-gemma-evidence.json
model: google/gemma-4-E2B-it
endpoint scope: 127.0.0.1
[ok] models endpoint
[ok] requested model advertised
[ok] chat action contract
local Gemma endpoint evidence OK
```

### Public demo environment

```text
python3 scripts/validate_public_env.py
[FAIL] PHX_HOST - set PHX_HOST to the public hostname
[FAIL] SECRET_KEY_BASE - set SECRET_KEY_BASE with mix phx.gen.secret or equivalent
[ok] PUBLIC_PORT - default 80
[ok] SIMULATOR_URL - http://simulator:8000
2 public environment check(s) failed
make: *** [public-env-check] Error 1
```

### Public live demo

```text
DEMO_URL="" SIMULATOR_PUBLIC_URL="" python3 scripts/validate_live_demo.py
DEMO_URL or --base-url is required
make: *** [live-demo-check] Error 2
```

### Final submission readiness

```text
SUBMISSION_GEMMA_MODE="local" python3 scripts/validate_submission_readiness.py
[ok] required local artifacts
[ok] lablab form matches draft - submission/lablab-form.json
[ok] submission bundle contents - submission/proteinloop-lablab-upload.zip
[ok] Local Gemma evidence - google/gemma-4-E2B-it via 127.0.0.1
[ok] public GitHub repository URL - https://github.com/Anarpego/ProteinLoop
[ok] application URL - https://proteinloop.dev-vb.lat
[FAIL] public GitHub repository reachable - https://github.com/Anarpego/ProteinLoop: <urlopen error [Errno 8] nodename nor servname provided, or not known>
[FAIL] application control reachable - https://proteinloop.dev-vb.lat: <urlopen error [Errno 8] nodename nor servname provided, or not known>
[FAIL] application producer route reachable - https://proteinloop.dev-vb.lat/producer: <urlopen error [Errno 8] nodename nor servname provided, or not known>
[ok] local git repository
[ok] local git commit - 64ffd38344cf090e03cf4453c3fd0c89524079d5
[ok] origin remote configured - git@github.com:Anarpego/ProteinLoop.git
[ok] origin matches lablab repository URL - origin=git@github.com:Anarpego/ProteinLoop.git lablab=https://github.com/Anarpego/ProteinLoop
3 submission readiness check(s) failed
make: *** [submission-ready-check] Error 1
```
