# Implementation Plan: Rendered Slide Deck

## Scope

- Use artifact-tool presentation JSX via generated slide modules.
- Keep the redesigned reusable deck generator in `scripts/generate_submission_deck_v2.mjs`.
- Store final PPTX and PDF artifacts in `submission/`.
- Add `scripts/validate_submission_artifacts.py`.

## Verification

- Build deck with artifact-tool and inspect contact sheet.
- Run artifact-tool layout QA.
- Validate PPTX internals with Python `zipfile`.
- Validate PDF page count and form/bundle references.
- Run project regression tests.
