# Implementation Plan: Manual Existing Repo Publish Path

## Scope

- Extend `scripts/publish_public_repo.py` with `--existing` and optional `--remote-url`.
- Keep the default behavior unchanged: missing `origin` still uses `gh repo create`.
- Add pure tests for existing-repo command planning and auth requirements.
- Update `Makefile`, README, and `deploy/public-repo.md`.

## Verification

- Run `python3 -m unittest tests.test_publish_public_repo`.
- Run `make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop EXISTING_REPO=1 DRY_RUN=1`.
- Run `make test`.
- Run `make submission-check`.
