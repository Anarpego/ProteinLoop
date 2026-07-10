# Implementation Plan: Immersive Agentic Tank

1. Add failing component, operator, producer, and hook source tests for the immersive contract.
2. Add an icon-only full-screen control to the reusable tank component.
3. Extend the Three.js hook with Fullscreen API entry, exit, state synchronization, resize, and teardown.
4. Add responsive `:fullscreen` layout rules for canvas, HUD, toolbar, and agent console.
5. Pass a compact operator-only slot that reuses the existing mission selection and execution events.
6. Run full tests, assets, Docker smoke, live-demo validation, and browser checks.
7. Publish implementation and evidence.

## Guardrails

- Reuse existing LiveView events and assigns.
- Keep the Python simulator and verifier authoritative.
- Do not duplicate agent execution state.
- Keep producer mode read-only.
- Preserve native Fullscreen API behavior and `Escape` handling.
