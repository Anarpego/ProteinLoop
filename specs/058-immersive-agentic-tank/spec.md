# Feature Spec: Immersive Agentic Tank

## Goal

Turn the real-time aquarium into an optional full-screen operating surface that combines the living tank, chemistry, deterministic scenario controls, and the real Agentic AI mission workflow.

## User Value

An operator can present and operate ProteinLoop from one immersive view: watch the ecosystem, trigger a deterministic emergency, choose an AI mission, run the specialist team, and retain visible safety and human-control boundaries without scrolling through the full dashboard.

## Functional Requirements

1. The tank shall expose a familiar full-screen icon button on operator and producer routes.
2. The control shall use the browser Fullscreen API, update its accessible label and pressed state, and allow native `Escape` exit behavior.
3. Entering or leaving full screen shall resize the Three.js renderer and camera without remounting or losing simulator state.
4. Full-screen mode shall keep the tank heading, current chemistry, biomass, health, and latest event visible as readable HTML.
5. The operator full-screen view shall retain the deterministic emergency and reset commands.
6. The operator full-screen view shall expose the existing mission selection and `run-agentic-mission` event rather than adding a parallel AI workflow.
7. The agent console shall show the selected mission, specialist count, local Gemma readiness, deterministic verifier boundary, and human approval boundary.
8. Running a mission from full screen shall preserve all existing verifier, trace, and HITL behavior.
9. The producer full-screen view shall remain read-only and shall not render emergency, reset, or agent mission controls.
10. Full-screen mode shall remain light, responsive, and free of overlap on desktop and mobile viewports.
11. Fullscreen event listeners shall be removed when the LiveView hook is destroyed.

## Acceptance Criteria

1. Component tests prove the full-screen control and optional agent console slot are rendered.
2. Operator LiveView tests prove the real mission options and run event are available in the immersive console.
3. Producer LiveView tests prove full-screen viewing remains read-only.
4. Source tests prove Fullscreen API entry, exit, change handling, resize, and listener cleanup.
5. Existing Phoenix and Python suites, production assets, Docker smoke, and live-demo validation pass.
6. Desktop and mobile browser checks prove full-screen canvas pixels are nonblank, controls fit, and the agent console does not obscure critical metrics.

## Non-Goals

- Full-screen mode does not create a second simulator or agent runtime.
- The agent console does not expose chain-of-thought.
- Producer permissions do not change.
- Full screen is optional; the normal scrolling dashboard remains available.
