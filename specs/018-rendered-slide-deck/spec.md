# Feature Spec: Rendered Slide Deck

## Goal

Turn the submission story into a visually polished editable PowerPoint and a matching PDF that can be submitted directly to lablab.

## User Value

The submission packet includes an editable `.pptx` deck and the `.pdf` format required by the lablab form. Both artifacts render the same verified ten-slide story.

## Functional Requirements

1. The repo shall include generated PowerPoint and PDF decks under `submission/`.
2. The deck shall contain a concise ProteinLoop pitch with real product proof, architecture, verifier, executable evidence, off-grid transport, HITL, and captured AMD-hosted Gemma evidence.
3. The opening and product-proof slides shall use real deployed application captures rather than an abstract placeholder cover.
4. The repo shall include a reproducible artifact-tool generator script.
5. The lablab form export and upload bundle shall identify and include the PDF presentation.
6. The repo shall include validation that checks required submission artifacts, the PPTX slide count, and the PDF page count.
7. README shall document both deck artifacts and the validation command.
8. The AMD proof shall distinguish the temporary notebook experiment from the durable public CPU deployment and shall report the validated 20-emergency repair result without implying training or a model-weight update.
9. The off-grid architecture shall explain how an on-site AMD GPU can run cached Gemma weights through ROCm/vLLM without an internet dependency while DECT NR+ carries the local field hop.
10. The deck shall distinguish internet independence from power independence: cloud synchronization is optional for local decisions, while measured solar and battery autonomy remain future field proof.
11. The deck shall use a cohesive editorial visual system with image-led product proof, restrained containers, deliberate light/dark rhythm, and at least five distinct macro-layout families.
12. The AMD result shall be visualized as a first-pass-to-verified-safety bridge rather than a generic equal-weight card grid.
13. The off-grid architecture shall use a visible local-farm containment boundary so judges can distinguish field transport, on-site AMD inference, producer control, optional cloud synchronization, and the separate power dependency.
14. The Unicorn Track story shall explicitly show product/market potential through a sourced aquaculture market signal, named initial buyers, a repeatable revenue model, and a tank-to-site-to-network expansion path.

## Acceptance Criteria

1. `submission/proteinloop-hackathon-deck.pptx` exists and has 10 slides.
2. `submission/proteinloop-hackathon-deck.pdf` exists and has 10 pages.
3. `submission/lablab-form.json` points `slide_presentation` to the PDF.
4. The deterministic upload bundle includes both the PDF and editable PPTX.
5. Artifact-tool layout QA reports 0 errors and 0 warnings during generation.
6. `python3 scripts/validate_submission_artifacts.py` passes.
7. Existing regression checks still pass.
8. The AMD evidence slide reports 2/20 first answers safe, 18 verifier-feedback repairs, 20/20 model-safe outcomes, and zero fallback, while labeling the result as captured inference-time evidence.
9. The safety-boundary diagram renders every node title and detail inside its assigned box with no overlap.
10. The off-grid architecture slide shows cached Gemma, ROCm/vLLM, the deterministic verifier, simulator, and local operator UI inside the on-site decision boundary, with cloud access shown only as optional synchronization.
11. The rendered contact sheet presents at least five visually distinct slide families, with no three consecutive slides sharing the same composition and no more than two card-grid compositions.
12. Kicker rows use named marker/label pairs and the final artifact-tool layout check reports zero unallowlisted errors or warnings.
13. Full-resolution review confirms that the safety flow, local-farm architecture, human decision panel, and AMD repair bridge remain legible without wrapped headings or decorative connector ambiguity.
14. At least one slide answers who pays, what they buy, how ProteinLoop earns recurring revenue, and how the initial farm deployment expands without inventing pricing or customer traction.
