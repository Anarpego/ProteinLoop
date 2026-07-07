# Feature Spec: Public Demo Compose Profile

## Goal

Add a production-oriented Docker Compose profile for deploying the public demo URL required by lablab.

## User Value

The team can deploy the same simulator and Phoenix app to a public host without exposing the simulator API directly or relying on local-only defaults.

## Functional Requirements

1. The repo shall include a public demo Compose file.
2. The public Compose file shall expose only the Phoenix web service by default.
3. The simulator shall remain private on the Compose network.
4. The web service shall require `PHX_HOST` and `SECRET_KEY_BASE` from the deployment environment.
5. The web service shall keep `SIMULATOR_URL=http://simulator:8000`.
6. The profile shall support optional `GEMMA_ENDPOINT`, `GEMMA_MODEL`, and `GEMMA_API_KEY`.
7. The repo shall include a stdlib-only validator for the public Compose profile.
8. README and live demo docs shall show how to use the profile and verify the URL.

## Acceptance Criteria

1. `make public-deploy-check` validates the public Compose profile.
2. `docker compose -f docker-compose.public.yml config` succeeds when required env vars are set.
3. Existing regression checks still pass.
