# Implementation Plan: Submission Bundle

## Scope

- Add `scripts/build_submission_bundle.py`.
- Write `submission/bundle-manifest.json`.
- Write `submission/proteinloop-lablab-upload.zip`.
- Update `scripts/validate_submission_artifacts.py`.
- Add `make submission-bundle`.
- Update README.

## Verification

- Run `python3 -m unittest tests.test_submission_bundle`.
- Run `make submission-bundle`.
- Run `make submission-check`.
- Run `make test`.
