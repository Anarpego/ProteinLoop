# Feature Spec: Rendered Slide Deck

## Goal

Turn the submission story into a visually polished editable PowerPoint and a matching PDF that can be submitted directly to lablab.

## User Value

The submission packet includes an editable `.pptx` deck and the `.pdf` format required by the lablab form. Both artifacts render the same verified ten-slide story.

## Functional Requirements

1. The repo shall include generated PowerPoint and PDF decks under `submission/`.
2. The deck shall contain a concise ProteinLoop pitch with real product proof, architecture, verifier, executable evidence, off-grid transport, HITL, and an honestly labeled AMD promotion path.
3. The opening and product-proof slides shall use real deployed application captures rather than an abstract placeholder cover.
4. The repo shall include a reproducible artifact-tool generator script.
5. The lablab form export and upload bundle shall identify and include the PDF presentation.
6. The repo shall include validation that checks required submission artifacts, the PPTX slide count, and the PDF page count.
7. README shall document both deck artifacts and the validation command.

## Acceptance Criteria

1. `submission/proteinloop-hackathon-deck.pptx` exists and has 10 slides.
2. `submission/proteinloop-hackathon-deck.pdf` exists and has 10 pages.
3. `submission/lablab-form.json` points `slide_presentation` to the PDF.
4. The deterministic upload bundle includes both the PDF and editable PPTX.
5. Artifact-tool layout QA reports 0 errors and 0 warnings during generation.
6. `python3 scripts/validate_submission_artifacts.py` passes.
7. Existing regression checks still pass.
