# Implementation Plan: Realistic Aquarium Scene

1. Add tests for the local PBR asset, license metadata, loader registration, and route contract.
2. Bundle the CC0 Barramundi Fish GLB and provenance record under Phoenix static assets.
3. Load and clone the fish model once while preserving the procedural fallback.
4. Refine fish scale and movement, then add a licensed realistic prawn visual with a segmented 3D fallback.
5. Keep prawns above the substrate line and in recognizable foreground positions.
6. Correct desktop/mobile overlay placement and clipping.
7. Run full tests, production asset build, Docker smoke, live-route validation, and visual checks.
8. Publish the implementation and refreshed evidence.

## Guardrails

- Python simulator state remains the source of truth.
- PBR asset failure must not leave the canvas blank.
- Runtime rendering must not depend on third-party hosts.
- Reuse model geometry and textures across fish instances.
- Keep draw calls and device pixel ratio bounded for laptop and mobile GPUs.
