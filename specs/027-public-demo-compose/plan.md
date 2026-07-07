# Implementation Plan: Public Demo Compose Profile

## Scope

- Add `docker-compose.public.yml`.
- Add `scripts/validate_public_deploy.py`.
- Add unit tests for profile validation helpers.
- Add `make public-deploy-check`.
- Update `deploy/live-demo.md` and README.

## Verification

- Run `python3 -m unittest tests.test_public_deploy_validator`.
- Run `make public-deploy-check`.
- Run `docker compose -f docker-compose.public.yml config` with dummy production env.
- Run existing test and artifact validators.
