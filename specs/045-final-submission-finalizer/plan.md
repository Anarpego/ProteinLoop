# Implementation Plan: Final Submission Finalizer

## Scope

- Add `scripts/finalize_submission.py`.
- Add `make submission-finalize`.
- Add unit tests for command order and failure behavior.
- Update README final submission instructions.

## Verification

- Run `python3 -m unittest tests.test_finalize_submission`.
- Run `make submission-finalize DRY_RUN=1`.
- Run `make test`.
- Run `make submission-check`.
- Run `make submission-ready-check` and confirm remaining failures are external.
