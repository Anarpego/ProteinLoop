# Implementation Plan: Real-Time Tank Simulation

1. Add failing component and LiveView tests for the canvas contract and live state patches.
2. Pin the researched Three.js package and make npm installation reproducible locally and in Docker.
3. Build a lifecycle-safe Phoenix hook with a procedural tank, fish, prawns, bubbles, plants, and state-driven animation.
4. Add a reusable operator-only real-time tank component with accessible HTML metrics and a static fallback.
5. Connect the deterministic emergency control and keep the AI mission immediately after the scene.
6. Update route validators and README demo instructions.
7. Run full tests, production asset build, Docker smoke, live-route checks, and responsive canvas verification.
8. Regenerate submission artifacts and publish the feature.

## Guardrails

- Python remains the ecosystem state authority.
- Visual interpolation may smooth values but may not invent state transitions.
- Keep all chemistry labels understandable before technical units.
- Keep WebGL resource count bounded and dispose resources on LiveView teardown.
- Preserve a meaningful non-WebGL fallback.
