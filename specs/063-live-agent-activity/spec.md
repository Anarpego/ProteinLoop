# Feature Spec: Live Agent Activity

## Goal

Make the real Agentic AI workflow visibly intelligent in the first viewport by showing truthful,
real-time progress from live tank observation through specialist briefs, supervisor synthesis,
deterministic verification, action application, and measured recovery.

## User Value

A producer or judge can tell that five coordinated agents are actively working, understand what
each role contributes, see where safety code takes control, and connect the final intervention to
the resulting water conditions without opening engineering evidence.

## Functional Requirements

1. The Sagents runtime shall emit progress events from actual execution boundaries rather than a
   timer or simulated animation.
2. Progress shall cover live-state observation, each of four specialist starts and structured
   completions, supervisor synthesis, verifier start and decision, action application, and outcome.
3. Progress callbacks shall be optional and shall never be allowed to break the agent runtime.
4. LiveView shall associate progress with one run identifier and ignore stale or post-completion
   events.
5. The first-viewport tank console shall show the current AI task and all five agent roles while a
   mission runs.
6. The main mission surface shall show an accessible activity stream and structured specialist
   statuses as they arrive.
7. Completed specialist summaries may expose structured recommendations, but the UI shall not
   expose or claim to expose hidden chain-of-thought.
8. The deterministic verifier shall remain visually and technically distinct from Gemma agents.
9. A failed or rejected run shall say that no rejected action was applied.
10. Motion shall encode running/completed state, stop under `prefers-reduced-motion`, and never be
    the only status signal.
11. Existing mission selection, HITL permissions, simulator ownership, and producer authorization
    shall remain unchanged.

## Acceptance Criteria

1. Runtime tests prove progress events correspond to actual subsystem, supervisor, verifier, and
   mutation boundaries.
2. LiveView tests pause a real async test run, inject progress through the runtime callback, and
   observe incremental UI changes before completion.
3. LiveView tests prove stale progress is ignored after a run completes.
4. Source tests prove visible text labels, live regions, reduced-motion handling, and no
   chain-of-thought claim.
5. Existing Phoenix and Python suites, production assets, Docker smoke, and live-demo validation
   pass.
6. Desktop and mobile browser checks are captured when browser tooling is available; unavailable
   tooling is reported.

## Non-Goals

- The activity monitor does not stream model tokens or private chain-of-thought.
- The feature does not add a second agent runtime or simulator.
- Idle animations do not claim that Gemma is running when no mission has been launched.
- The monitor does not bypass deterministic verification or producer approval.

