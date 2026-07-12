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

Off-grid AI for living protein systems: Gemma 4, DECT NR+, and deterministic safety.

## 2. One Loop, Shared Risk

A chemistry failure does not stop at the vegetables. Fish, prawns, plants, feed reserve, and eggs depend on the same biological loop.

## 3. Product Proof

The deployed product makes animal behavior, plain-language chemistry, biomass, and the next action understandable in one living operator view.

## 4. Visible Recovery

The operator watches observation, four specialist briefs, supervisor synthesis, verification, execution, and measured recovery as structured runtime events.

## 5. Safety Boundary

Gemma can recommend, but only `verify_ecosystem_safety` can admit simulator mutation. Every role has a separate title and detail region; unsafe proposals are rejected, recorded, and returned as verifier feedback before state changes.

## 6. Executable Evidence

The simulator is also the policy evaluator and RLVR source of truth. The one-click judge path injects an emergency, rejects an unsafe proposal, admits recovery, and exposes measured chemistry.

## 7. Off-Grid Architecture

Two physical nRF9151 boards prove the private DECT NR+ field hop. After provisioning, an on-site AMD GPU can serve cached Gemma 4 weights through ROCm/vLLM while the deterministic verifier, simulator, Phoenix UI, and producer controls remain local. Internet access is optional for evidence synchronization and model updates, not for the action path. The captured AMD notebook run proves the software stack; a farm-installed AMD GPU, physical probes, and measured solar autonomy remain explicitly labeled next proofs.

## 8. Producer Control

Risky or irreversible actions stop for approve, apply-half, or reject. Edited actions are verified again before execution.

## 9. Captured AMD Gemma Proof

`google/gemma-4-E2B-it` ran through vLLM on the assigned Act-II AMD notebook using PyTorch 2.10, ROCm 7.2, a `gfx1100` GPU, and 47.98 GiB memory. Only 2/20 first answers were safe. Exact verifier feedback repaired the remaining 18, producing 20/20 model-safe plans with zero fallback. The experiment observed 139 requests, 60,385 tokens, 99.793 completion tokens/s, and 655.522 ms median client latency. It used inference-time repair with no training or weight update. The public site remains a durable private CPU deployment and displays this as captured evidence.

## 10. Ask

Protect protein production where connectivity cannot be assumed. ProteinLoop combines a private field link, local intelligence, executable safety, and producer control for farms, cooperatives, and food-security programs.
