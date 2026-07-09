# Feature Spec: Docker Smoke Verification

## Goal

Add an executable smoke test for the Docker Compose submission path.

## User Value

Judges and collaborators can run one command after `docker compose up` to verify that the simulator, dashboard, producer route, RLVR panel, forecast endpoint, and core recovery path are live.

## Functional Requirements

1. The repo shall include a smoke test script using only Python standard library.
2. The script shall verify simulator `/health`, `/forecast/anomaly`, `/rlvr/evaluation`, reset, ammonia spike, and safety recovery.
3. The script shall verify the operator dashboard renders the core demo panels.
4. The script shall verify the Spanish producer route renders approval and offline fallback controls.
5. The repo shall expose the smoke test through a Make target.
6. The Make target shall write `submission/docker-smoke-evidence.json` with check names, pass/fail state, and service URLs for the final readiness report.

## Acceptance Criteria

1. `make docker-smoke` passes when Docker Compose services are running.
2. README documents the smoke test command.
3. `submission/docker-smoke-evidence.json` exists after `make docker-smoke`.
4. Existing local regression checks still pass.
