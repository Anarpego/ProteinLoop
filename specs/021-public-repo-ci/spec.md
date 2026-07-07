# Feature Spec: Public Repo CI

## Goal

Prepare the public GitHub repository path with automated CI that proves the core simulator, Phoenix app, submission packet, and Docker demo remain runnable after push.

## User Value

Judges and collaborators can see executable evidence on GitHub that the repository builds, tests, and smoke-tests the same vertical slice documented in the README.

## Functional Requirements

1. The repo shall include a GitHub Actions workflow for push, pull request, and manual dispatch.
2. The workflow shall run Python simulator tests with Python 3.11.
3. The workflow shall run Phoenix formatting and tests with Elixir/OTP versions aligned to the Docker image.
4. The workflow shall validate submission artifacts without requiring presentation rendering.
5. The workflow shall build Docker Compose services and run the Docker smoke test against the running stack.
6. CI shall not require AMD ROCm hardware or live Gemma credentials.
7. The repo shall include a local stdlib-only validator for the workflow contract.

## Acceptance Criteria

1. `.github/workflows/ci.yml` exists and uses researched current GitHub Action release tags.
2. `make ci-check` validates the workflow contract locally.
3. README documents CI coverage and local pre-push checks.
4. Existing local regression checks still pass.
