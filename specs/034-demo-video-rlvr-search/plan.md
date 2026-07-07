# Implementation Plan: Demo Video RLVR Search Scene

## Scope

- Extend `scripts/generate_demo_video.py` to read `rlvr_training` evidence.
- Add an eighth scene focused on best-so-far verifier search.
- Update video generator unit tests.
- Regenerate the demo video, bundle, and readiness report.

## Verification

- Run `python3 -m unittest tests.test_demo_video_generator`.
- Run `python3 scripts/generate_demo_video.py`.
- Run `make submission-bundle`.
- Run `make submission-check`.
- Run `make test`.
