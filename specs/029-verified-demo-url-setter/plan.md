# Implementation Plan: Verified Demo URL Setter

## Scope

- Add `scripts/set_demo_url.py`.
- Reuse pure functions from `scripts/validate_live_demo.py`.
- Add unit tests with fake check functions.
- Add `make set-demo-url`.
- Update README and `deploy/live-demo.md`.

## Verification

- Run `python3 -m unittest tests.test_set_demo_url`.
- Run dry-run command.
- Run full test and submission validators.
