# Implementation Plan: Realistic Aquarium Scene

1. Add tests for the local PBR asset, license metadata, loader registration, and route contract.
2. Bundle the CC0 Barramundi Fish GLB and provenance record under Phoenix static assets.
3. Load and clone the fish model once while preserving the procedural fallback.
4. Refine fish and prawn scale, movement, materials, aquarium glass, water, substrate, lighting, and camera framing.
5. Correct desktop/mobile overlay placement and clipping.
6. Run full tests, production asset build, Docker smoke, live-route validation, and visual checks.
7. Publish the implementation and refreshed evidence.

## Guardrails

- Python simulator state remains the source of truth.
- PBR asset failure must not leave the canvas blank.
- Runtime rendering must not depend on third-party hosts.
- Reuse model geometry and textures across fish instances.
- Keep draw calls and device pixel ratio bounded for laptop and mobile GPUs.
