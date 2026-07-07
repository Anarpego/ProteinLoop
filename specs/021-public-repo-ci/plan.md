# Implementation Plan: Public Repo CI

## Scope

- Add a GitHub Actions workflow for simulator, Phoenix, submission, and Docker smoke verification.
- Pin workflow actions to researched current release tags:
  - `actions/checkout@v7.0.0`
  - `actions/setup-python@v6.3.0`
  - `erlef/setup-beam@v1.24.1`
  - `docker/setup-buildx-action@v4.2.0`
- Keep AMD Gemma ROCm deployment out of CI because it needs specialized GPU hardware and credentials.
- Add `scripts/validate_ci_workflow.py` so workflow drift is caught without depending on GitHub.
- Expose the validator as `make ci-check`.

## Verification

- Run `python3 scripts/validate_ci_workflow.py`.
- Run Python simulator tests.
- Run Phoenix formatting and tests.
- Run submission artifact validation.
- Run Docker smoke verification when Compose services are available.
