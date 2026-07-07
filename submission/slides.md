# ProteinLoop Slide Source

Rendered deck: `submission/proteinloop-hackathon-deck.pptx`

Regenerate with:

```sh
node scripts/generate_submission_deck.mjs
node /Users/anibalperez/.codex/plugins/cache/openai-primary-runtime/presentations/26.521.10419/skills/presentations/scripts/build_artifact_deck.mjs --slides-dir outputs/manual-proteinloop/presentations/submission-deck/slides --out submission/proteinloop-hackathon-deck.pptx --preview-dir outputs/manual-proteinloop/presentations/submission-deck/preview --layout-dir outputs/manual-proteinloop/presentations/submission-deck/layout --contact-sheet outputs/manual-proteinloop/presentations/submission-deck/contact-sheet.png --slide-count 10
```

## 1. ProteinLoop

An agentic loop that closes the protein cycle.

## 2. Problem

Aquaponics is promising but incomplete for rural food security. Vegetables are not enough; families need reliable daily protein.

## 3. Product

ProteinLoop coordinates fish, freshwater prawns, duckweed, hydroponic plants, and chickens in one closed loop.

## 4. Why Agents

The system is too dynamic to operate manually: feed, oxygen, ammonia, nitrate, harvest timing, and node health all interact.

## 5. Verifier-Gated Harness

Models propose actions. The simulator verifier decides whether the action can mutate state.

Proof: unsafe overfeeding is rejected before state changes.

## 6. Collapse Versus Recovery

The demo injects an ammonia spike, shows unsafe rejection, then applies a safe recovery action.

## 7. RLVR

The simulator reward scores survival, biomass, water quality, and mortality. The RLVR panel compares naive and safety policies.

## 8. Multi-Agent Topology

Subsystem agents cover fish tank, hydroponia, duckweed/chickens, and supervisor roles.

## 9. Self-Healing Mesh

Edge node failure migrates agents to healthy nodes while preserving identity and state tokens.

## 10. Spanish HITL

Risky water exchange and harvest actions pause for producer approval in Spanish: approve, edit, or reject.

## 11. Sagents-Compatible Loop

Explicit steps: `call_llm`, `verify_ecosystem_safety`, `execute_tools`, `until_tool`.

## 12. AMD Gemma Path

`GEMMA_ENDPOINT` points to AMD-hosted Gemma through vLLM/ROCm using `vllm/vllm-openai-rocm:gemma4`.

## 13. Market

Rural families and cooperatives in Latin America need low-cost, resilient protein production.

## 14. Business Model

Community mesh node plus shared cloud agent subscription; local producers use Spanish mobile-first approval flows.

## 15. Ask

ProteinLoop turns aquaponics from a fragile expert system into a verifier-gated agentic protein platform.
