# Implementation Plan: Generated Demo Video

## Scope

- Add `scripts/generate_demo_video.py`.
- Use Pillow to render storyboard frames.
- Write a Motion-JPEG AVI container with Python stdlib.
- Update `scripts/validate_submission_artifacts.py`.
- Update `make submission-render`.
- Document the artifact in README.

## Verification

- Run `python3 scripts/generate_demo_video.py`.
- Run `make submission-check`.
- Run `make test`.
