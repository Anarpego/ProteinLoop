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

Four subsystem agents cover fish tank, freshwater prawn, hydroponia, and duckweed/chickens; a fifth parent supervisor closes the cycle.

## 9. Self-Healing Mesh

Two real BEAM nodes run Sagents through Horde. Stopping the managed agent's actual owner restores it on the surviving peer while preserving identity, state token, and canonical state fingerprint.

## 10. Physical DECT NR+

Two physical nRF9151 DKs exchange bidirectional DECT NR+ traffic. FT `1051223739` and PT `1051239227` each sent locally and received the peer's matching sequence number in a read-only, non-simulated capture with no flash or reset.

## 11. Human Approval

Risky water exchange and harvest actions pause for an English producer decision: approve, apply half, or reject.

## 12. Real Sagents Runtime

Sagents 0.9.0 runs four Gemma subsystem agents plus a parent supervisor, gates `close_cycle` through `verify_ecosystem_safety`, and terminates with `until_tool_success`.

## 13. Proven Gemma Runtime

`google/gemma-4-E2B-it` runs locally through llama.cpp/Metal behind `GEMMA_ENDPOINT`; the same boundary can later move to vLLM/ROCm without changing the agent code.

## 14. Market

Rural families and cooperatives in Latin America need low-cost, resilient protein production.

## 15. Business Model

Community mesh node plus shared cloud agent subscription; local producers use a plain-language, mobile-first approval flow.

## 16. Ask

ProteinLoop turns aquaponics from a fragile expert system into a verifier-gated agentic protein platform.
