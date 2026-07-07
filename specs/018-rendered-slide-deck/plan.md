# Implementation Plan: Rendered Slide Deck

## Scope

- Use artifact-tool presentation JSX via generated slide modules.
- Keep reusable deck generator in `scripts/generate_submission_deck.mjs`.
- Store final PPTX in `submission/`.
- Add `scripts/validate_submission_artifacts.py`.

## Verification

- Build deck with artifact-tool and inspect contact sheet.
- Run artifact-tool layout QA.
- Validate PPTX internals with Python `zipfile`.
- Run project regression tests.
