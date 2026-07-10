# Feature Spec: Realistic Aquarium Scene

## Goal

Replace the toy-like animal primitives and oversized framing with a credible, polished aquarium scene while preserving the existing one-second simulator contract.

## User Value

A first-time user should immediately recognize a working aquaculture tank, living fish, freshwater prawns, aeration, plants, and changing water conditions without mistaking the scene for a static cartoon.

## Functional Requirements

1. The primary fish shall use a locally bundled PBR glTF asset rather than sphere and triangle primitives when WebGL asset loading succeeds.
2. The selected Barramundi Fish asset shall come from the Khronos glTF Sample Assets repository, retain its CC0 license record, and require no runtime CDN request.
3. The hook shall load the model once, clone it with shared geometry and textures, and keep a procedural fish fallback when loading fails.
4. Fish shall use natural scale, spacing, orientation, depth, banking, and muted material response rather than candy-colored oversized bodies.
5. Prawns shall use a locally bundled, license-compatible realistic visual when texture loading succeeds and retain the segmented 3D prawn as a loading/error fallback.
6. Prawns shall be large enough to recognize, remain above the visible substrate line, occupy foreground depth, and preserve bottom-dwelling motion.
7. The scene shall improve depth through realistic glass, water transmission, surface movement, substrate variation, soft shadows, and balanced aquarium lighting.
8. The camera shall frame the complete tank and connected grow bed on wide and mobile viewports without clipping animals or infrastructure.
9. The heading, commands, and live HUD shall remain inside their viewport bounds and shall not obscure the primary animal focal area.
10. Ammonia, dissolved oxygen, biomass, collapse state, reduced-motion behavior, pointer response, and one-second LiveView updates shall preserve their existing deterministic behavior.
11. GPU and loaded model and texture resources shall be released when the LiveView hook is destroyed.
12. The pinned Three.js package shall remain `0.185.1`, the latest researched package for official release `r185` on 2026-07-10.

## Acceptance Criteria

1. Source tests prove `GLTFLoader` loads the local model and the model license record is bundled.
2. The fish GLB and prawn texture checksums and expected sizes are tested so accidental asset replacement is detectable.
3. Existing component and LiveView tests prove readable metrics and read-only producer behavior remain unchanged.
4. Phoenix and Python test suites, production assets, Docker smoke, and live-demo validation pass.
5. Desktop and mobile screenshots show nonblank WebGL pixels, complete framing, continuous motion, readable overlays, and no horizontal clipping.

## Non-Goals

- The visual layer does not add independent ecosystem physics.
- The fish and prawn visuals do not identify the exact simulated production species.
- The change does not alter verifier rules, simulator values, agent decisions, or producer approvals.
