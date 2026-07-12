# ProteinLoop Slide Source

Rendered decks: editable `submission/proteinloop-hackathon-deck.pptx` and upload-ready `submission/proteinloop-hackathon-deck.pdf`.

Regenerate with:

```sh
PRESENTATION_WORKSPACE=outputs/manual-proteinloop/presentations/submission-deck node scripts/generate_submission_deck_v2.mjs
node /Users/anibalperez/.codex/plugins/cache/openai-primary-runtime/presentations/26.521.10419/skills/presentations/scripts/build_artifact_deck.mjs --slides-dir outputs/manual-proteinloop/presentations/submission-deck/slides --out submission/proteinloop-hackathon-deck.pptx --preview-dir outputs/manual-proteinloop/presentations/submission-deck/preview --layout-dir outputs/manual-proteinloop/presentations/submission-deck/layout --contact-sheet outputs/manual-proteinloop/presentations/submission-deck/contact-sheet.png --slide-count 10
node /Users/anibalperez/.codex/plugins/cache/openai-primary-runtime/presentations/26.521.10419/skills/presentations/scripts/check_layout_quality.mjs --layout outputs/manual-proteinloop/presentations/submission-deck/layout --allowlist scripts/presentation_layout_allowlist.json
PRESENTATION_PREVIEW_DIR=outputs/manual-proteinloop/presentations/submission-deck/preview python3 scripts/export_slide_pdf.py
```

## 1. ProteinLoop

Local AI for living protein systems: Gemma 4, DECT NR+, and deterministic safety keep the food-control loop recoverable when cloud access disappears.

## 2. One Loop, Shared Risk

One ammonia spike threatens every protein output. Fish, prawns, plants, feed reserve, and eggs depend on the same biological loop.

## 3. Product Proof

The deployed product makes animal behavior, plain-language chemistry, biomass, and the next action understandable in one living operator view.

## 4. Visible Recovery

The operator watches observation, four specialist briefs, supervisor synthesis, verification, execution, and measured recovery as structured runtime events.

## 5. Safety Boundary

Gemma can recommend. It cannot mutate. Only `verify_ecosystem_safety` can admit simulator state change; unsafe proposals are rejected, recorded, and returned as verifier feedback first.

## 6. Business Case

Aquaculture is a $371B farm-gate market producing 103 million tonnes of aquatic animals, according to FAO SOFIA 2026. ProteinLoop starts with hard-to-connect fish and prawn farms, cooperatives, and food-security programs. The proposed model combines edge commissioning with annual site software and support, then expands from tank to site to cooperative network.

## 7. Off-Grid Architecture

Two physical nRF9151 boards prove the private DECT NR+ field hop. After provisioning, an on-site AMD GPU can serve cached Gemma 4 weights through ROCm/vLLM while the deterministic verifier, simulator, Phoenix UI, and producer controls remain local. Internet access is optional for evidence synchronization and model updates, not for the action path. The captured AMD notebook run proves the software stack; a farm-installed AMD GPU, physical probes, and measured solar autonomy remain explicitly labeled next proofs.

## 8. Producer Control

The workflow pauses at the only irreversible boundary. The producer sees live chemistry and a verified plan before choosing approve, apply-half, or reject; edited actions are verified again.

## 9. Captured AMD Gemma Proof

`google/gemma-4-E2B-it` ran through vLLM on the assigned Act-II AMD notebook using PyTorch 2.10, ROCm 7.2, a `gfx1100` GPU, and 47.98 GiB memory. Only 2/20 first answers were safe. Exact verifier feedback repaired the remaining 18, producing 20/20 model-safe plans with zero fallback. The experiment observed 139 requests, 60,385 tokens, 99.793 completion tokens/s, and 655.522 ms median client latency. It used inference-time repair with no training or weight update. The public site remains a durable private CPU deployment and displays this as captured evidence.

## 10. Ask

From one tank to the operating layer for resilient aquatic food. ProteinLoop lands with off-grid fish and prawn farms, earns through deployment plus recurring site software/support, and expands through farms, cooperatives, and food-security programs.
