# Implementation Plan: Public Repo Publish Helper

## Scope

- Add `scripts/publish_public_repo.py`.
- Add pure tests for URL generation and lablab draft replacement.
- Add `make publish-repo`.
- Update `deploy/public-repo.md` and README.

## Verification

- Run `python3 -m unittest tests.test_publish_public_repo`.
- Run `make publish-repo GITHUB_REPOSITORY=Anarpego/proteinloop DRY_RUN=1`.
- Run `make test`.
