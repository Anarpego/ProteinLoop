# Feature Spec: Real-Time Tank Simulation

## Goal

Replace the static operator illustration with a living, game-like tank that makes the one-second simulator stream visible through motion and environmental change.

## User Value

A first-time user can see fish and prawns living inside the tank, recognize whether the water is healthy, trigger a visible emergency, and watch a verified AI intervention change the same scene without first interpreting a technical dashboard.

## Functional Requirements

1. The operator route shall render an animated WebGL tank as its primary system view.
2. The tank shall contain visibly distinct fish, freshwater prawns, bubbles, water, substrate, plants, and connected loop infrastructure.
3. The scene shall animate continuously and respond subtly to pointer movement without requiring instructions.
4. Phoenix LiveView shall update scene inputs from the existing simulator snapshot stream every second.
5. Ammonia shall control water clarity and warning color.
6. Dissolved oxygen shall control bubble activity, fish speed, and whether fish move toward the surface.
7. Fish and prawn biomass shall influence the visible animal scale while preserving stable layout bounds.
8. Critical or collapsed state shall produce a visibly distressed scene without replacing deterministic health copy.
9. The scene shall expose current health, day, ammonia, oxygen, fish biomass, and prawn biomass as readable HTML outside the canvas.
10. A visible `Simulate water emergency` command shall use the existing deterministic ammonia-spike event so users can immediately see real-time behavior.
11. The primary AI mission shall remain directly after the tank, and its resulting state change shall update the same scene.
12. The implementation shall pin Three.js `0.185.1`, the latest researched official package version for release `r185` on 2026-07-10.
13. The hook shall resize responsively, cap device pixel ratio, respect reduced-motion preference, and dispose GPU resources when destroyed.
14. A static visual fallback and accessible tank description shall remain available when WebGL or JavaScript is unavailable.
15. The producer route and deterministic simulator/verifier boundary shall remain unchanged.

## Acceptance Criteria

1. Component tests prove the canvas hook, fallback, readable metrics, and simulator data attributes are present.
2. LiveView tests prove a simulator snapshot patches the tank ammonia, oxygen, day, and health inputs.
3. Source tests prove Three.js is pinned and the hook is registered with LiveSocket.
4. Existing mission, DECT, producer, HITL, verifier, and light-theme tests continue to pass.
5. A production asset build includes the Three.js scene without external runtime CDN requests.
6. Docker smoke and live-demo checks pass against the updated operator route.
7. Desktop and mobile browser checks prove the canvas is nonblank, correctly framed, animated, and free of incoherent overlap.

## Non-Goals

- The WebGL scene does not implement independent ecosystem physics.
- Pointer interaction does not mutate simulator state.
- The stock nRF9151 `hello_dect` capture is not presented as chemical sensor telemetry.
