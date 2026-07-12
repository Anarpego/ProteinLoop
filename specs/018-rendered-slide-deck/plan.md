# Implementation Plan: Rendered Slide Deck

## Scope

- Use artifact-tool presentation JSX via generated slide modules.
- Keep the redesigned reusable deck generator in `scripts/generate_submission_deck_v2.mjs`.
- Store final PPTX and PDF artifacts in `submission/`.
- Add `scripts/validate_submission_artifacts.py`.
- Repair the safety-boundary node geometry and replace the generic edge-compute label with an explicit offline AMD deployment path.
- Restyle the complete deck around an editorial aquaculture/engineering system: stronger typography, fewer outlines, image-led proof, a local-farm containment diagram, and a data-led AMD repair bridge.
- Rebalance the technical story for the Unicorn Track by replacing redundant test exposition with sourced market context, buyer/value/revenue logic, and a credible land-and-expand path.

## Verification

- Build deck with artifact-tool and inspect contact sheet.
- Run artifact-tool layout QA.
- Inspect the safety and off-grid architecture slides at full resolution for text containment, connector direction, proof boundaries, and offline-operation clarity.
- Validate PPTX internals with Python `zipfile`.
- Validate PDF page count and form/bundle references.
- Run project regression tests.
- Score the final contact sheet against the presentation comeback rubric and iterate any dimension below four.
