# Implementation Plan: Final Readiness Report

## Scope

- Add `scripts/generate_readiness_report.py`.
- Add tests for status summarization, blocker extraction, and markdown rendering.
- Add `make readiness-report`.
- Update README submission instructions and project layout.
- Generate `submission/final-readiness-report.md`.

## Verification

- Run `python3 -m unittest tests.test_readiness_report`.
- Run `make readiness-report`.
- Run `make test`.
- Run `make submission-check`.
- Run `make submission-ready-check` and confirm remaining failures are external.
