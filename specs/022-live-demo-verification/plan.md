# Implementation Plan: Live Demo Verification

## Scope

- Add `scripts/validate_live_demo.py`.
- Keep the script dependency-free and usable from local shell, CI, or a deployment machine.
- Add focused unit tests for URL normalization and HTML marker checks.
- Add `make live-demo-check`.
- Add `deploy/live-demo.md` with a public deployment checklist.

## Verification

- Run `python3 -m unittest tests.test_live_demo_validator`.
- Run `make live-demo-check DEMO_URL=http://127.0.0.1:4001` against the current Compose stack.
- Run the broader regression checks touched by the new script and Make target.
