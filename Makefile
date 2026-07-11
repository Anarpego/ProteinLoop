.PHONY: test demo serve web-deps web-assets web-test web-serve submission-render submission-check submission-bundle submission-form submission-finalize demo-rehearsal mesh-evidence sagents-evidence horde-up horde-evidence nrf9151-plan nrf9151-bridge nrf9151-live-evidence readiness-report submission-ready-check docker-smoke ci-check live-demo-check credit-check gemma-check local-gemma-install local-gemma-start local-gemma-status local-gemma-check local-gemma-submission-evidence local-gemma-stop local-gemma-command public-env-check public-deploy-check publish-repo set-demo-url

LOCAL_GEMMA_HOST ?= 127.0.0.1
LOCAL_GEMMA_PORT ?= 8001
LOCAL_GEMMA_CONTEXT_SIZE ?= 8192
LOCAL_GEMMA_WAIT_SECONDS ?= 1800
SUBMISSION_GEMMA_MODE ?= local

test:
	python3 -m unittest discover -s tests

demo:
	PYTHONPATH=sim python3 -m proteinloop_sim demo --days 8 --spike-day 1

serve:
	PYTHONPATH=sim python3 -m proteinloop_sim serve --host 127.0.0.1 --port 8000

web-deps:
	cd app && mix deps.get

web-assets:
	cd app && mix assets.setup && mix assets.build

web-test:
	cd app && mix test

web-serve:
	cd app && SIMULATOR_URL=http://127.0.0.1:8000 PORT=4001 mix phx.server

submission-render:
	python3 scripts/generate_demo_evidence.py
	python3 scripts/generate_demo_rehearsal.py
	python3 scripts/generate_nrf9151_field_plan.py
	python3 scripts/nrf9151_telemetry_bridge.py --sample --write-submission
	cd app && mix run scripts/export_mesh_evidence.exs
	python3 scripts/render_cover_png.py
	python3 scripts/generate_demo_video.py
	python3 scripts/export_lablab_form.py
	node scripts/generate_submission_deck_v2.mjs
	node /Users/anibalperez/.codex/plugins/cache/openai-primary-runtime/presentations/26.521.10419/skills/presentations/scripts/build_artifact_deck.mjs --slides-dir outputs/manual-proteinloop/presentations/submission-deck/slides --out submission/proteinloop-hackathon-deck.pptx --preview-dir outputs/manual-proteinloop/presentations/submission-deck/preview --layout-dir outputs/manual-proteinloop/presentations/submission-deck/layout --contact-sheet outputs/manual-proteinloop/presentations/submission-deck/contact-sheet.png --slide-count 10
	python3 scripts/export_slide_pdf.py
	python3 scripts/build_submission_bundle.py
	SUBMISSION_GEMMA_MODE="$(SUBMISSION_GEMMA_MODE)" python3 scripts/generate_readiness_report.py

submission-check:
	python3 scripts/validate_submission_artifacts.py

submission-bundle:
	python3 scripts/build_submission_bundle.py

submission-form:
	python3 scripts/export_lablab_form.py

submission-finalize:
	SUBMISSION_GEMMA_MODE="$(SUBMISSION_GEMMA_MODE)" python3 scripts/finalize_submission.py $(if $(DRY_RUN),--dry-run,)

demo-rehearsal:
	python3 scripts/generate_demo_rehearsal.py

mesh-evidence:
	cd app && mix run scripts/export_mesh_evidence.exs

sagents-evidence:
	cd app && GEMMA_ENDPOINT="$${GEMMA_ENDPOINT:-http://127.0.0.1:8001}" GEMMA_MODEL="$${GEMMA_MODEL:-google/gemma-4-E2B-it}" mix run scripts/export_sagents_evidence.exs

horde-up:
	docker compose -f docker-compose.yml -f docker-compose.horde.yml up -d --build

horde-evidence:
	python3 scripts/horde_failover_test.py --write-evidence

nrf9151-plan:
	python3 scripts/generate_nrf9151_field_plan.py

nrf9151-bridge:
	python3 scripts/nrf9151_telemetry_bridge.py --sample --write-submission

nrf9151-live-evidence:
	python3 scripts/nrf9151_live_capture.py --write-submission

readiness-report:
	SUBMISSION_GEMMA_MODE="$(SUBMISSION_GEMMA_MODE)" python3 scripts/generate_readiness_report.py

submission-ready-check:
	SUBMISSION_GEMMA_MODE="$(SUBMISSION_GEMMA_MODE)" python3 scripts/validate_submission_readiness.py

docker-smoke:
	python3 scripts/docker_smoke_test.py --write-evidence

ci-check:
	python3 scripts/validate_ci_workflow.py

live-demo-check:
	DEMO_URL="$(DEMO_URL)" SIMULATOR_PUBLIC_URL="$(SIMULATOR_PUBLIC_URL)" python3 scripts/validate_live_demo.py

credit-check:
	FIREWORKS_API_KEY="$(FIREWORKS_API_KEY)" FIREWORKS_BASE_URL="$(FIREWORKS_BASE_URL)" AMD_CLOUD_STATUS="$(AMD_CLOUD_STATUS)" python3 scripts/validate_credit_access.py

gemma-check:
	GEMMA_ENDPOINT="$(GEMMA_ENDPOINT)" GEMMA_MODEL="$(GEMMA_MODEL)" GEMMA_API_KEY="$(GEMMA_API_KEY)" python3 scripts/validate_gemma_endpoint.py

local-gemma-install:
	python3 scripts/local_gemma.py --host "$(LOCAL_GEMMA_HOST)" --port "$(LOCAL_GEMMA_PORT)" install

local-gemma-start:
	python3 scripts/local_gemma.py --host "$(LOCAL_GEMMA_HOST)" --port "$(LOCAL_GEMMA_PORT)" start --context-size "$(LOCAL_GEMMA_CONTEXT_SIZE)" --wait-seconds "$(LOCAL_GEMMA_WAIT_SECONDS)"

local-gemma-status:
	python3 scripts/local_gemma.py --host "$(LOCAL_GEMMA_HOST)" --port "$(LOCAL_GEMMA_PORT)" status

local-gemma-check:
	python3 scripts/local_gemma.py --host "$(LOCAL_GEMMA_HOST)" --port "$(LOCAL_GEMMA_PORT)" check

local-gemma-submission-evidence:
	python3 scripts/local_gemma.py --host "$(LOCAL_GEMMA_HOST)" --port "$(LOCAL_GEMMA_PORT)" check --evidence-file submission/local-gemma-evidence.json

local-gemma-stop:
	python3 scripts/local_gemma.py --host "$(LOCAL_GEMMA_HOST)" --port "$(LOCAL_GEMMA_PORT)" stop

local-gemma-command:
	python3 scripts/local_gemma.py --host "$(LOCAL_GEMMA_HOST)" --port "$(LOCAL_GEMMA_PORT)" print-command --context-size "$(LOCAL_GEMMA_CONTEXT_SIZE)"

public-env-check:
	python3 scripts/validate_public_env.py

public-deploy-check:
	python3 scripts/validate_public_deploy.py

publish-repo:
	python3 scripts/publish_public_repo.py "$(GITHUB_REPOSITORY)" $(if $(EXISTING_REPO),--existing,) $(if $(PUBLISH_REMOTE_URL),--remote-url "$(PUBLISH_REMOTE_URL)",) $(if $(DRY_RUN),--dry-run,)

set-demo-url:
	python3 scripts/set_demo_url.py "$(DEMO_URL)" $(if $(DRY_RUN),--dry-run,)
