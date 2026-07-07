# Feature Spec: Rendered Slide Deck

## Goal

Turn the markdown slide source into an editable PowerPoint artifact that can be submitted directly to lablab.

## User Value

The submission packet now includes a real `.pptx` deck, not only slide notes. The generated deck can be opened, edited, and uploaded for judging.

## Functional Requirements

1. The repo shall include a generated PowerPoint deck under `submission/`.
2. The deck shall contain a concise ProteinLoop pitch with architecture, verifier, demo evidence, self-healing, HITL, and AMD Gemma slides.
3. The repo shall include a reproducible generator script.
4. The repo shall include a validation script that checks required submission artifacts and the PPTX slide count.
5. README shall document the deck artifact and validation command.

## Acceptance Criteria

1. `submission/proteinloop-hackathon-deck.pptx` exists and has 10 slides.
2. Artifact-tool layout QA reports 0 errors and 0 warnings during generation.
3. `python3 scripts/validate_submission_artifacts.py` passes.
4. Existing regression checks still pass.
