# ProteinLoop

ProteinLoop is a hackathon prototype for an agentic aquaponic protein loop: fish, prawns, duckweed, hydroponic plants, and chickens coordinated by a deterministic safety harness and Gemma-powered Sagents agents.

The first vertical slice is a Python simulator and verifier. It proves the core demo behavior: a naive routine collapses after an ammonia spike, while a safety-aware harness policy stabilizes the ecosystem.

The second slice is a Phoenix LiveView app. It consumes the simulator API, broadcasts state through PubSub, renders a judge/operator dashboard, and includes a Spanish producer approval route.

The third slice is an agent harness. It proposes structured actions, routes every proposal through the simulator verifier before execution, and shows accepted/rejected proposals in the operator dashboard.

The fourth slice adds provider control and RLVR traces. Every harness run appends a JSONL record with state, action, verifier result, reward, and provider metadata.

The fifth slice makes those traces inspectable: the operator dashboard renders a recent trace timeline, and the Python CLI can summarize the JSONL artifact.

The sixth slice adds a one-click judge demo cascade. The operator dashboard can reset the simulator, inject an ammonia spike, show an unsafe agent proposal rejected by the verifier, run a safe recovery proposal, and append both outcomes to the RLVR trace artifact.

The seventh slice makes the model boundary visible. The dashboard shows the configured OpenAI-compatible `GEMMA_ENDPOINT`, selected `GEMMA_MODEL`, and a `Check model` control that probes `/v1/models` without blocking the core simulator demo.

The eighth slice adds a lightweight RLVR reward panel. The simulator scores naive and safety policies across repeatable scenarios, exposes the reward verifier payload through the API, and renders reward improvement on the operator dashboard.

The ninth slice makes the multi-agent topology visible. The operator dashboard derives advisory cards for fish tank, freshwater prawn, hydroponia, duckweed/chickens, and supervisor agents from simulator state while keeping mutation behind the verified harness.

The tenth slice adds a local self-healing mesh demo. The operator dashboard can simulate an edge node loss, migrate subsystem agents to healthy nodes, recover the failed node, and show migration events.

The eleventh slice connects Spanish HITL approval to the operator flow. Risky water exchange and duckweed harvest actions pause through Sagents HumanInTheLoop until the producer approves, edits, or rejects them; the decision resumes the interrupted Sagents tool.

The twelfth slice originally added a deterministic loop fallback. It remains for credential-free tests, while the active runtime is the real Sagents integration described below.

The thirteenth slice adds the AMD Gemma deployment profile. It includes `.env.example`, a ROCm/vLLM Compose profile using `vllm/vllm-openai-rocm:gemma4`, and a runbook for connecting AMD-hosted Gemma to `GEMMA_ENDPOINT`.

The fourteenth slice adds submission materials: MIT license, lablab submission draft, video script, slide source, and a cover SVG.

The fifteenth slice adds deterministic anomaly forecasting. The simulator forecasts routine-operation ammonia/oxygen risk without mutating live state, exposes `GET /forecast/anomaly`, and renders the near-term risk on the operator dashboard.

The sixteenth slice adds offline producer fallback. The producer route now includes deterministic Spanish emergency guidance that works without model access or cloud connectivity.

The seventeenth slice renders the submission deck. The repo now includes an editable PowerPoint deck at `submission/proteinloop-hackathon-deck.pptx` plus a validation script for the submission packet.

The eighteenth slice adds Docker smoke verification. After `docker compose up`, `make docker-smoke` checks simulator health, forecast, RLVR, reset/spike/recovery, the operator dashboard, and the Spanish producer route.

The CI readiness slice adds public repository CI. GitHub Actions now runs simulator tests, Phoenix formatting/tests, submission artifact validation, Docker Compose build, and the Docker smoke test without requiring AMD ROCm hardware or live Gemma credentials.

The live demo verification slice adds an executable check for the submitted demo URL. `make live-demo-check DEMO_URL=https://...` verifies the operator dashboard and Spanish producer route, with optional simulator API checks when `SIMULATOR_PUBLIC_URL` is set.

The Gemma endpoint verification slice adds `make gemma-check`, which verifies `/v1/models`, verifies `/v1/chat/completions` returns a valid ProteinLoop action, and writes `submission/gemma-evidence.json` on success.

The generated demo video slice adds a deterministic video artifact at `submission/proteinloop-demo-video.avi`, built from the existing script and evidence without requiring `ffmpeg`.

The submission bundle slice adds `submission/proteinloop-lablab-upload.zip` and `submission/bundle-manifest.json` so the upload packet can be archived and checksum-verified as one artifact set.

The public demo Compose slice adds `docker-compose.public.yml`, a production-oriented profile that exposes only Phoenix and keeps the simulator private on the Compose network.

The public repository publish helper adds `make publish-repo GITHUB_REPOSITORY=owner/name`, which creates or uses a public GitHub repo, pushes `main`, and updates the lablab repository URL.

The verified demo URL setter adds `make set-demo-url DEMO_URL=https://...`, which checks the public dashboard and Spanish producer route before updating the lablab Application URL.

The lablab form export slice adds `submission/lablab-form.json`, a structured copy/paste packet with artifact paths and unresolved URL fields.

The final readiness report slice adds `submission/final-readiness-report.md`, a generated handoff report that records passing local gates, failing external gates, and the exact commands needed before lablab upload.

The producer message packet slice adds a provider-free Spanish SMS/WhatsApp handoff message to the producer view, reusing the same HITL approval and offline emergency rules.

The RLVR policy improvement slice adds a dependency-free verifier-guided policy search loop with CLI, API, dashboard, and generated evidence output.

The generated demo video now includes an RLVR policy search scene so the submitted AVI matches the current dashboard and evidence packet.

The demo rehearsal packet adds `submission/demo-rehearsal.json` and `.md`, generated from simulator behavior to prove the judge path before the public deployment is available.

The mesh evidence packet adds `submission/mesh-evidence.json` and `.md`, generated from the Elixir mesh model to prove agent migration and state-token preservation.

The live nRF9151 evidence slice records read-only UART output from two physical DECT NR+ boards. FT `1051223739` and PT `1051239227` each sent locally and received the peer's matching sequence number; the artifact is marked `simulated: false`, and no flash or reset command was invoked.

The DECT operator/producer slice loads that evidence directly into both LiveViews. The operator can replay sequence `#100` as an explicitly simulated sensor alert and then run the verified Gemma agents; the Spanish producer view shows the same real-radio status without presenting `hello_dect` as chemical sensor telemetry.

The nRF9151 field plan maps PT to the tank edge node and FT to the community gateway/controller. Nordic's stock `hello_dect` firmware proves the physical radio link; it does not claim to carry ProteinLoop sensor telemetry yet.

The nRF9151 telemetry bridge packet maps sample two-board JSONL readings into simulator and dashboard events, proving how a critical tank reading becomes an ammonia-spike request and how an offline edge node becomes a mesh failure hint.

The real Sagents runtime slice pins Sagents `0.9.0` and LangChain `0.9.2`, starts `Sagents.Supervisor` under OTP, runs four real `Sagents.SubAgent` workers with Gemma concurrently, inserts `verify_ecosystem_safety` before tool execution, terminates through `until_tool_success`, and preserves executable JSON/Markdown evidence at `submission/sagents-evidence.*`.

The real Horde failover slice pins Horde `0.10.0`, runs two distributed BEAM nodes with participation membership, persists managed Sagents state atomically, stops the probe's actual owner service, restores the same agent on the survivor, and verifies identity, state token, and canonical fingerprint preservation in `submission/horde-evidence.*`.

## Workflow

This repo is set up for a Spec Kit-style flow:

- `.specify/memory/constitution.md` defines project principles.
- `specs/001-simulator-verifier/spec.md` defines the first feature.
- `specs/001-simulator-verifier/plan.md` defines the implementation plan.
- `specs/001-simulator-verifier/tasks.md` tracks executable tasks.
- `specs/003-agent-harness/spec.md` defines the current agent harness slice.
- `specs/004-provider-traces/spec.md` defines provider selection and trace recording.
- `specs/007-demo-cascade/spec.md` defines the repeatable one-click judge demo.
- `specs/008-model-endpoint-status/spec.md` defines model endpoint visibility.
- `specs/009-rlvr-reward-panel/spec.md` defines the lightweight RLVR reward verifier view.
- `specs/010-subsystem-agent-topology/spec.md` defines deterministic subsystem agent topology.
- `specs/011-self-healing-mesh/spec.md` defines the local self-healing mesh demo.
- `specs/012-spanish-hitl-queue/spec.md` defines the connected Spanish HITL approval queue.
- `specs/013-sagents-loop-contract/spec.md` defines the superseded deterministic loop fallback.
- `specs/014-amd-gemma-deployment/spec.md` defines the AMD Gemma vLLM deployment profile.
- `specs/015-submission-packet/spec.md` defines the hackathon submission packet.
- `specs/016-anomaly-forecast/spec.md` defines near-term ammonia/oxygen risk prediction.
- `specs/017-offline-emergency-fallback/spec.md` defines the Spanish offline emergency rule path.
- `specs/018-rendered-slide-deck/spec.md` defines the rendered PowerPoint deck artifact.
- `specs/019-docker-smoke-verification/spec.md` defines the runnable Docker smoke check.
- `specs/020-demo-evidence-packet/spec.md` defines generated demo evidence artifacts.
- `specs/021-public-repo-ci/spec.md` defines the public GitHub Actions CI path.
- `specs/022-live-demo-verification/spec.md` defines the public demo URL verification path.
- `specs/024-gemma-endpoint-verification/spec.md` defines the OpenAI-compatible Gemma endpoint verification path.
- `specs/030-lablab-form-export/spec.md` defines the structured lablab form export.
- `specs/031-final-readiness-report/spec.md` defines the generated final readiness handoff report.
- `specs/032-producer-message-packet/spec.md` defines the Spanish SMS/WhatsApp handoff packet.
- `specs/033-rlvr-policy-improvement/spec.md` defines the verifier-guided policy search curve.
- `specs/034-demo-video-rlvr-search/spec.md` defines the generated video update for the policy search scene.
- `specs/035-demo-rehearsal-packet/spec.md` defines the executable judge demo rehearsal packet.
- `specs/036-mesh-evidence-packet/spec.md` defines the generated self-healing mesh evidence packet.
- `specs/037-nrf9151-field-plan/spec.md` defines the two-board DECT NR+ field extension plan.
- `specs/038-nrf9151-telemetry-bridge/spec.md` defines the two-board telemetry bridge contract.
- `specs/047-real-sagents-runtime/spec.md` defines the real Sagents, Gemma, verifier, and HITL runtime.
- `specs/048-real-horde-failover/spec.md` defines the two-node Sagents/Horde failover proof.
- `specs/049-live-nrf9151-evidence/spec.md` defines read-only physical two-board DECT NR+ evidence.
- `specs/051-dect-operator-producer/spec.md` defines the live DECT evidence panels, simulated replay, and Gemma action.

`AGENTS.md` captures the Superpowers-style operating rules: spec first, tight tasks, TDD, review, and verification before completion.

## Run Tests

From the repo root:

```sh
python3 -m unittest discover -s tests
```

Expected result:

```text
Ran 155 tests

OK
```

Run the Phoenix tests:

```sh
cd app
mix deps.get
mix test
```

Current expected result: `101 tests, 0 failures`.

Validate the GitHub Actions workflow contract before pushing:

```sh
make ci-check
```

The workflow uses the current release tags checked on GitHub Releases:

- `actions/checkout@v7.0.0`
- `actions/setup-python@v6.3.0`
- `erlef/setup-beam@v1.24.1`
- `docker/setup-buildx-action@v4.2.0`

Phoenix dependency pins were refreshed against Hex on July 7, 2026:

- `phoenix` latest stable: `1.8.9`.
- `phoenix_live_view` latest stable: `1.2.6`.
- `websock_adapter` latest stable: `0.6.0` through dependency resolution.
- Existing pins for `phoenix_html`, `phoenix_live_reload`, `lazy_html`, `esbuild`, `tailwind`, `bandit`, `req`, `gettext`, `jason`, `dns_cluster`, `telemetry_metrics`, and `telemetry_poller` already matched the latest stable Hex releases checked during the refresh.

Run the final submission readiness gate:

```sh
make submission-ready-check
```

The default local profile requires a reachable public GitHub repository and Application URL, matching `origin`, `submission/local-gemma-evidence.json`, and the real Sagents proof. Set `SUBMISSION_GEMMA_MODE=remote` only when validating an AMD-hosted or Fireworks endpoint; remote mode additionally requires non-loopback `submission/gemma-evidence.json`.

The final Application URL must be public. Localhost, loopback, and private-network URLs are intentionally rejected by `make submission-ready-check`.

After the public demo URL and the selected Gemma evidence are available, run the finalizer so generated artifacts are rebuilt in the correct order:

```sh
make submission-finalize
```

Preview the sequence without running it:

```sh
make submission-finalize DRY_RUN=1
```

Validate a public or local demo URL:

```sh
make live-demo-check DEMO_URL=http://127.0.0.1:4001
```

When the simulator API is public too:

```sh
make live-demo-check \
  DEMO_URL=https://your-demo-url \
  SIMULATOR_PUBLIC_URL=https://your-simulator-url
```

Preview updating the lablab Application URL:

```sh
make set-demo-url DEMO_URL=https://your-demo-url DRY_RUN=1
```

After the public route checks pass, `make set-demo-url` updates both `submission/lablab-submission.md` and `submission/lablab-form.json`.

Validate the public deployment Compose profile:

```sh
make public-deploy-check
```

Validate public deployment environment values:

```sh
SECRET_KEY_BASE="$(cd app && mix phx.gen.secret)"
PHX_HOST=your-demo-host \
SECRET_KEY_BASE="$SECRET_KEY_BASE" \
make public-env-check
```

Verify hackathon credit access before deploying Gemma:

```sh
FIREWORKS_API_KEY=your-fireworks-key \
AMD_CLOUD_STATUS=active \
make credit-check
```

Set `AMD_CLOUD_STATUS=active` only after the AMD Cloud console shows active credits and GPU quota. The Fireworks check calls the OpenAI-compatible `/models` endpoint and fails clearly when the API key or credits are not usable.

Validate an AMD-hosted or fallback OpenAI-compatible Gemma endpoint:

```sh
GEMMA_ENDPOINT=https://your-vllm-host \
GEMMA_MODEL=google/gemma-4-E2B-it \
make gemma-check
```

On success, the check writes `submission/gemma-evidence.json`.

The evidence must show that `/v1/models` advertises the requested Gemma 4 model and that `/v1/chat/completions` returns a valid ProteinLoop action.

Run the smallest Gemma 4 model, E2B IT, locally on Apple Silicon before using AMD cloud credits:

```sh
make local-gemma-install
make local-gemma-start
make local-gemma-check
```

The first start downloads Google's official QAT Q4 GGUF weights (about 2.9 GB for E2B weights, plus its multimodal projection/cache metadata). After that, the model runs offline at `http://127.0.0.1:8001/v1`. `make local-gemma-check` writes development evidence to `outputs/local-gemma-evidence.json`; `make local-gemma-submission-evidence` writes the strict local-profile artifact to `submission/local-gemma-evidence.json`. The managed server disables thinking for reliable low-latency JSON actions; the deterministic verifier still gates mutation. See `deploy/local-gemma.md` for lifecycle commands, memory assumptions, and the optional AMD promotion path.

With Docker and local Gemma running, generate the real Sagents proof:

```sh
make sagents-evidence
```

The target defaults to local E2B at `http://127.0.0.1:8001` and the simulator at `http://127.0.0.1:8000`; explicit environment variables still override both for AMD deployment. It runs four subsystem agents, a verified supervisor cycle, a HumanInTheLoop interrupt, and a rejection resume with zero mutation. It writes `submission/sagents-evidence.json` and `.md`.

Start the two-node Horde overlay and generate the state-preserving failover proof:

```sh
make horde-up
make horde-evidence
```

The overlay runs `proteinloop_web@web` on port `4001` and `proteinloop_peer@peer` on port `4012`, sharing Sagents persistence through a Docker volume. The verifier runs a real Gemma cycle, stops whichever service owns the managed agent, observes restoration on the survivor, restarts the stopped node, and writes `submission/horde-evidence.json` and `.md`.

With both nRF9151 DKs connected on their recorded VCOM0 ports, capture fresh physical DECT NR+ proof:

```sh
make nrf9151-live-evidence
```

The capture opens both ports read-only at 115200 baud, listens concurrently, and only replaces `submission/nrf9151-live-evidence.json` and `.md` when both FT and PT locally send and receive peer traffic. It never invokes a flash or reset command.

Summarize harness traces:

```sh
PYTHONPATH=sim python3 -m proteinloop_sim traces --path app/priv/traces/harness.jsonl
```

Run the lightweight RLVR policy evaluation:

```sh
PYTHONPATH=sim python3 -m proteinloop_sim rlvr
```

## Run the Demo

```sh
PYTHONPATH=sim python3 -m proteinloop_sim demo --days 8 --spike-day 1
```

The output compares two policies:

- `naive`: fixed feeding and low aeration, no chemistry response.
- `safety`: deterministic recovery policy that cuts feed, increases aeration, and exchanges water within verifier limits.

The current demo shows the naive system collapsing and the safety policy recovering.

## Run the Simulator API

```sh
PYTHONPATH=sim python3 -m proteinloop_sim serve --host 127.0.0.1 --port 8000
```

Endpoints:

- `GET /health`
- `GET /state`
- `POST /reset`
- `POST /scenario/ammonia_spike`
- `POST /step`
- `POST /policy/safety_step`
- `GET /rlvr/evaluation`
- `GET /rlvr/training`
- `GET /forecast/anomaly`

Example:

```sh
curl -X POST http://127.0.0.1:8000/scenario/ammonia_spike
curl -X POST http://127.0.0.1:8000/policy/safety_step
curl http://127.0.0.1:8000/state
```

## Run the LiveView App

Start the simulator first:

```sh
make serve
```

In another terminal:

```sh
cd app
mix deps.get
mix assets.setup
mix assets.build
SIMULATOR_URL=http://127.0.0.1:8000 PORT=4001 mix phx.server
```

Routes:

- Operator dashboard: `http://localhost:4001/`
- Producer HITL and phone handoff: `http://localhost:4001/producer`

If port `4000` is free, omit `PORT=4001`.

## Agent Harness

The harness lives in `app/lib/proteinloop/agent/`.

Local demo providers:

- `:stub_safe`: emits a context-aware action that should pass the simulator verifier.
- `:stub_unsafe`: emits an overfeeding action that should be rejected before mutation.

The operator dashboard has buttons for both paths. Rejected proposals keep the prior simulator state and show verifier violations.

The operator dashboard also includes `Run demo cascade`, which executes the core pitch flow in one action: reset, ammonia spike, unsafe verifier rejection, safe recovery, and trace recording.

The dashboard also includes a provider selector:

- safe stub;
- unsafe stub;
- OpenAI-compatible.

The dashboard also includes model endpoint status. `Check model` probes `GEMMA_ENDPOINT/v1/models` and reports reachable, auth-required, unreachable, or not-configured status. This is the quick AMD-hosted Gemma or Fireworks fallback sanity check.

The dashboard includes an `RLVR reward verifier` panel. It compares the naive baseline against the safety candidate across repeatable simulator scenarios and shows average reward delta, recovered collapse scenarios, and collapse avoidance rate.

The same panel includes a deterministic policy search curve from `GET /rlvr/training`. Candidate policies are scored by `SafetyVerifier.reward`, and the dashboard shows best-so-far improvement without requiring any training framework.

The dashboard includes `Subsystem agent topology` cards for fish tank, freshwater prawn, hydroponia, duckweed/chickens, and the parent supervisor. State mutation still goes through the harness and simulator verifier.

The dashboard includes a `Self-healing mesh` panel whose real Sagents/Horde status band shows distribution mode, participation membership, connected BEAM nodes, and managed-agent count. The `Simulate node loss` and `Recover node` controls remain a deterministic rehearsal; the actual service-stop proof is generated by `make horde-evidence`.

The physical hardware proof uses two Nordic nRF9151 DKs running Nordic `hello_dect`: PT `1051239227` maps to the tank sensor edge node and FT `1051223739` maps to the community gateway/controller. The committed evidence requires matching FT-to-PT and PT-to-FT sequence numbers from read-only serial capture. Connected boards are not required to replay Docker or CI; submission checks validate the captured artifact.

The first panel below the dashboard metrics is `Physical DECT NR+ link`. It shows the latest matching sequence and both board identities. `Replay sensor alert` maps that radio capture into the deterministic ammonia-spike simulator scenario, and `Run Gemma on simulator state` starts the same verifier-gated Sagents cycle as the main Gemma control. `/producer` shows the compact `Ultimo enlace DECT NR+` status. Both views explicitly separate the physical radio proof from simulated water-quality values.

Separately, the stdlib telemetry bridge converts sample nRF9151 JSONL records into the future sensor contract: critical tank telemetry maps to `POST /scenario/ammonia_spike`, while an offline gateway report maps to the dashboard `mesh-fail-node` action. Those sample water-quality values are not attributed to the stock `hello_dect` logs.

The dashboard includes a `Spanish HITL approval` panel. `Request producer approval` asks Gemma for an irreversible tool call, Sagents HumanInTheLoop pauses it before mutation, and the producer route resumes that same Sagents call with approve, edit-to-half, or reject.

The dashboard includes a `Real Sagents runtime` panel. `Run Gemma agents` runs four subsystem agents concurrently and passes their reports to a fifth parent supervisor. The custom `verify_ecosystem_safety` mode calls the simulator's non-mutating verifier before execution, and `until_tool_success` returns the accepted action, final state, reward, and verifier evidence.

The dashboard includes an `Anomaly forecast` panel. It forecasts near-term ammonia and oxygen risk under routine operation without mutating live simulator state, then recommends early intervention when chemistry is trending toward collapse.

The producer route includes a `Respaldo offline` panel. It applies deterministic Spanish emergency rules to the current readings, so a producer still gets clear local guidance when model/cloud services are unavailable.

The producer route also includes `Mensaje WhatsApp/SMS`: a short provider-free Spanish text packet with tank status, proposed action, offline guidance, and `APROBAR` / `MITAD` / `RECHAZAR` reply options for low-bandwidth handoff.

Harness runs append trace data to:

```text
app/priv/traces/harness.jsonl
```

Each JSONL row contains the original state, proposed action, verifier result, resulting state, reward, provider, and timestamp. This is the first RLVR training artifact.

The dashboard renders the latest trace rows under `Trace timeline`. The Python trace summary reports accepted/rejected counts, provider counts, average accepted reward, and the latest verifier violations.

Optional OpenAI-compatible model boundary:

```sh
GEMMA_ENDPOINT=http://your-vllm-host:8000 \
GEMMA_API_KEY=optional \
GEMMA_MODEL=google/gemma-4-E2B-it \
SIMULATOR_URL=http://127.0.0.1:8000 \
PORT=4001 \
mix phx.server
```

The model endpoint is expected to expose `/v1/chat/completions` and return a JSON action with:

- `feed_kg`
- `aeration_hours`
- `water_exchange_fraction`
- `duckweed_harvest_kg`
- `note`

## Docker

Build and run the full demo:

```sh
docker compose up --build
```

Routes:

- Simulator API: `http://127.0.0.1:8000`
- Operator dashboard: `http://localhost:4001/`
- Producer HITL: `http://localhost:4001/producer`

Use `Run demo cascade` on the operator dashboard for the fastest end-to-end judge path.

The web container talks to the simulator at `http://simulator:8000` inside the Compose network. RLVR trace output is persisted in the `proteinloop_traces` Docker volume.

Smoke-test the running Docker demo:

```sh
make docker-smoke
```

On success this writes `submission/docker-smoke-evidence.json`, which the final readiness report consumes without rerunning local HTTP checks from inside the report generator.

## Public Repo CI

The GitHub Actions workflow lives at `.github/workflows/ci.yml`.

It runs on push, pull request, and manual dispatch. The first job runs `make test`, Phoenix dependency install, `mix format --check-formatted`, `mix test`, and `make submission-check`. The second job builds Docker Compose, starts the stack, runs `python3 scripts/docker_smoke_test.py`, prints logs on failure, and shuts the stack down.

CI intentionally skips `docker-compose.gemma-rocm.yml` because AMD-hosted Gemma requires ROCm hardware and credentials. Validate that profile separately on an AMD host with the runbook below.

## Public Repository

The GitHub publication checklist is documented in `deploy/public-repo.md`.

The local repository already has commits. Publishing requires either a valid GitHub CLI session or an already-created public GitHub repository that Git can push to. The helper sets `origin`, pushes `main`, replaces `Public GitHub Repository: TODO` in `submission/lablab-submission.md`, and regenerates `submission/lablab-form.json` after a successful push. If `origin` already exists, it must match `GITHUB_REPOSITORY`; the helper refuses mismatched remotes so the submission draft cannot point at a different repo than the one pushed.

Preview the publish steps:

```sh
make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop DRY_RUN=1
```

If GitHub CLI auth is invalid, create the public repo in the browser first, then use the existing-repo path:

```sh
make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop EXISTING_REPO=1 DRY_RUN=1
make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop EXISTING_REPO=1
```

For SSH remotes:

```sh
make publish-repo \
  GITHUB_REPOSITORY=Anarpego/proteinloop \
  EXISTING_REPO=1 \
  PUBLISH_REMOTE_URL=git@github.com:Anarpego/proteinloop.git
```

## Live Demo Deployment

The public demo deployment checklist is documented in `deploy/live-demo.md`.

Before adding the demo URL to lablab, run:

```sh
DEMO_URL=https://your-demo-url make live-demo-check
```

That check verifies the two judge-facing routes:

- Operator dashboard: `/`
- Spanish producer path: `/producer`

For a public host, use:

```sh
SECRET_KEY_BASE="$(cd app && mix phx.gen.secret)"
PHX_HOST=your-demo-host \
SECRET_KEY_BASE="$SECRET_KEY_BASE" \
make public-env-check

PHX_HOST=your-demo-host \
SECRET_KEY_BASE="$SECRET_KEY_BASE" \
docker compose -f docker-compose.public.yml up -d --build
```

## AMD Gemma Deployment

The AMD-hosted Gemma path is documented in `deploy/amd-gemma-vllm.md`.

The local Apple Silicon rehearsal path is documented in `deploy/local-gemma.md`. It serves the same `google/gemma-4-E2B-it` model alias through the same OpenAI-compatible API before the AMD credit activation window starts.

Validate the profile syntax locally:

```sh
docker compose -f docker-compose.gemma-rocm.yml --profile amd-gemma config
```

Run it only on an AMD ROCm host:

```sh
cp .env.example .env
docker compose --env-file .env -f docker-compose.gemma-rocm.yml --profile amd-gemma up -d
```

Then set `GEMMA_ENDPOINT` for the Phoenix app, use `Check model`, select `OpenAI-compatible`, and run the harness. The simulator verifier still gates every model proposal.

Verify the endpoint from the repo root:

```sh
make gemma-check
```

## Submission Packet

Submission source artifacts live in `submission/`:

- `lablab-submission.md`: title, descriptions, tags, and demo notes.
- `video-script.md`: 2-3 minute demo recording script.
- `slides.md`: pitch deck source.
- `proteinloop-hackathon-deck.pptx`: editable PowerPoint deck.
- `proteinloop-demo-video.avi`: generated storyboard video artifact.
- `cover.svg`: cover image source.
- `cover.png`: rendered upload-ready cover image.
- `demo-evidence.json` / `demo-evidence.md`: generated simulator evidence for video and submission copy.
- `demo-rehearsal.json` / `demo-rehearsal.md`: generated judge-path rehearsal with unsafe rejection, recovery, RLVR search, and Spanish HITL copy.
- `mesh-evidence.json` / `mesh-evidence.md`: generated self-healing mesh migration and state-token evidence.
- `sagents-evidence.json` / `sagents-evidence.md`: live local Gemma evidence for real Sagents agents, custom safety mode, `until_tool_success`, and non-mutating HITL rejection.
- `local-gemma-evidence.json`: live loopback proof that the local OpenAI-compatible endpoint advertises Gemma 4 E2B and returns a structured ProteinLoop action.
- `horde-evidence.json` / `horde-evidence.md`: real two-node Sagents/Horde owner loss, state restoration, and node-rejoin evidence.
- `nrf9151-live-evidence.json` / `nrf9151-live-evidence.md`: read-only, non-simulated bidirectional DECT NR+ evidence from the two physical nRF9151 DKs.
- `nrf9151-field-plan.json` / `nrf9151-field-plan.md`: exact FT/PT board inventory and ProteinLoop field-role mapping.
- `nrf9151-telemetry-bridge.json` / `nrf9151-telemetry-bridge.md`: sample two-board JSONL bridge evidence for simulator and dashboard events.
- `docker-smoke-evidence.json`: generated Docker Compose smoke evidence for simulator, dashboard, producer route, and recovery endpoints.
- `gemma-evidence.json`: optional remote-profile artifact generated after `make gemma-check` succeeds against a non-loopback OpenAI-compatible endpoint.
- `proteinloop-lablab-upload.zip`: generated bundle containing the upload packet, local Gemma proof, lablab form JSON, final readiness report, Docker smoke evidence, and remote Gemma evidence when it exists.
- `bundle-manifest.json`: file sizes and SHA-256 checksums for the bundle contents.
- `lablab-form.json`: structured lablab form fields and artifact paths.
- `final-readiness-report.md`: generated pass/fail handoff report for final external gates.

The repo includes a root `LICENSE` with MIT terms.

Validate the submission packet:

```sh
python3 scripts/validate_submission_artifacts.py
```

Validate final readiness after the public repo and demo URL exist:

```sh
make submission-finalize
```

Regenerate and validate with Make:

```sh
make submission-render
make submission-check
```

Build only the upload bundle:

```sh
make submission-bundle
```

Export structured lablab form fields:

```sh
make submission-form
```

Generate the executable judge-path rehearsal packet:

```sh
make demo-rehearsal
```

Generate the self-healing mesh evidence packet:

```sh
make mesh-evidence
```

Generate the real Sagents and local Gemma evidence packet:

```sh
make sagents-evidence
```

Generate the real two-node Horde failover evidence packet:

```sh
make horde-evidence
```

Capture fresh live evidence from both connected nRF9151 DKs:

```sh
make nrf9151-live-evidence
```

Reload `/` after capture, or press `Refresh` in the `Physical DECT NR+ link` panel. Docker mounts `submission/nrf9151-live-evidence.json` read-only at `/evidence/nrf9151-live-evidence.json`.

Generate the nRF9151 two-board DECT NR+ field plan:

```sh
make nrf9151-plan
```

Generate the nRF9151 sample telemetry bridge evidence:

```sh
make nrf9151-bridge
```

Generate the final readiness handoff report:

```sh
make readiness-report
```

## Project Layout

```text
.
├── .specify/                       # Spec Kit-style project memory
├── specs/001-simulator-verifier/   # First feature spec/plan/tasks
├── specs/002-liveview-dashboard/    # Phoenix LiveView spec/plan/tasks
├── specs/003-agent-harness/         # Agent harness spec/plan/tasks
├── specs/004-provider-traces/       # Provider controls + RLVR traces
├── specs/005-full-docker/           # Full Docker Compose submission path
├── specs/006-trace-timeline/        # Trace timeline + Python summary
├── specs/007-demo-cascade/          # One-click judge demo cascade
├── specs/008-model-endpoint-status/ # Model endpoint visibility
├── specs/009-rlvr-reward-panel/     # Lightweight RLVR reward verifier
├── specs/010-subsystem-agent-topology/ # Deterministic subsystem agents
├── specs/011-self-healing-mesh/     # Local self-healing mesh demo
├── specs/012-spanish-hitl-queue/    # Connected Spanish HITL approval queue
├── specs/013-sagents-loop-contract/ # Superseded deterministic loop fallback
├── specs/014-amd-gemma-deployment/  # AMD Gemma/vLLM deployment profile
├── specs/015-submission-packet/     # Hackathon submission packet
├── specs/016-anomaly-forecast/      # Near-term ammonia/oxygen forecast
├── specs/017-offline-emergency-fallback/ # Spanish offline emergency guidance
├── specs/018-rendered-slide-deck/   # Rendered PowerPoint deck artifact
├── specs/019-docker-smoke-verification/ # Runnable Docker smoke check
├── specs/020-demo-evidence-packet/  # Generated demo evidence packet
├── specs/021-public-repo-ci/       # GitHub Actions CI for public repo
├── specs/022-live-demo-verification/ # Public demo URL verification
├── specs/023-submission-readiness-gate/ # Final submission readiness gate
├── specs/024-gemma-endpoint-verification/ # Gemma endpoint evidence gate
├── specs/026-submission-bundle/    # Zip bundle for upload artifacts
├── specs/027-public-demo-compose/  # Public deployment Compose profile
├── specs/028-public-repo-publish-helper/ # Public GitHub publish helper
├── specs/029-verified-demo-url-setter/ # Verified lablab demo URL setter
├── specs/030-lablab-form-export/ # Structured lablab form export
├── specs/031-final-readiness-report/ # Final readiness handoff report
├── specs/032-producer-message-packet/ # Spanish SMS/WhatsApp handoff packet
├── specs/033-rlvr-policy-improvement/ # RLVR policy search improvement
├── specs/034-demo-video-rlvr-search/ # Demo video policy-search scene
├── specs/035-demo-rehearsal-packet/ # Executable demo rehearsal packet
├── specs/036-mesh-evidence-packet/ # Self-healing mesh evidence packet
├── specs/037-nrf9151-field-plan/ # Two-board nRF9151 field plan
├── specs/038-nrf9151-telemetry-bridge/ # Two-board nRF9151 bridge contract
├── specs/047-real-sagents-runtime/ # Real Sagents + Gemma + HITL runtime
├── specs/048-real-horde-failover/ # Real two-node Sagents/Horde migration
├── specs/049-live-nrf9151-evidence/ # Physical two-board DECT NR+ capture
├── specs/051-dect-operator-producer/ # DECT UI, replay, and Gemma control
├── specs/045-final-submission-finalizer/ # Ordered final upload sequence
├── .github/workflows/ci.yml        # Public repository CI workflow
├── deploy/                          # Deployment runbooks
├── submission/                      # lablab copy, video script, slides, cover
├── app/                             # Phoenix LiveView application
├── sim/proteinloop_sim/            # Python simulator package
├── tests/                          # stdlib unittest suite
├── AGENTS.md                       # Agent workflow rules
├── Dockerfile
├── app/Dockerfile
├── docker-compose.yml
├── docker-compose.public.yml
├── docker-compose.gemma-rocm.yml
├── LICENSE
├── scripts/generate_submission_deck.mjs
├── scripts/generate_demo_video.py
├── scripts/build_submission_bundle.py
├── scripts/docker_smoke_test.py
├── scripts/validate_ci_workflow.py
├── scripts/validate_live_demo.py
├── scripts/validate_gemma_endpoint.py
├── scripts/validate_public_deploy.py
├── scripts/publish_public_repo.py
├── scripts/set_demo_url.py
├── scripts/export_lablab_form.py
├── scripts/finalize_submission.py
├── scripts/validate_submission_readiness.py
├── scripts/validate_submission_artifacts.py
└── goal.md                         # Original master plan
```

## Remaining External Gates

The public repository and local Gemma profile are prepared. Final submission readiness still needs:

1. Deploy the Docker app to a public URL and run `make live-demo-check`.
2. Replace the TODO Application URL in `submission/lablab-submission.md` with `make set-demo-url`.
3. Run `SUBMISSION_GEMMA_MODE=local make submission-finalize`.

AMD-hosted or Fireworks inference remains an optional remote profile. Use `SUBMISSION_GEMMA_MODE=remote make submission-finalize` only after `make credit-check` and `make gemma-check` pass against that host.
