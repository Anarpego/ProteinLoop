# Feature Spec: Producer Decision Handoff

## Goal

Make the operator-to-producer approval workflow self-explanatory and keep the result visible at the point of action. A user shall never need to guess that the generic Producer link contains a pending decision or scroll below a sticky control bar to discover whether the action succeeded.

## User Value

- The operator sees whether producer review is idle, waiting, processing, approved, reduced, or rejected.
- The producer sees the proposed action and decision controls before the large tank visualization.
- After a decision, the controls become a clear receipt with current chemistry and a direct return to the operator tank.

## Functional Requirements

1. The operator header link shall be labeled `Producer view` when idle.
2. A pending request shall change that link to `Producer decision waiting`, use warning emphasis, and expose an accessible pending count.
3. A processing request shall read `Producer decision processing`.
4. The latest resolved decision shall be visible from the operator route as approved, reduced, or rejected without requiring another producer-page visit.
5. The producer route shall render the proposed action and decision controls before the live tank.
6. The producer decision workspace shall use one visible set of Approve, Apply half, and Reject controls.
7. A completed decision shall replace those controls with an assertive but non-disruptive result receipt in the same workspace.
8. The result receipt shall state whether simulator mutation occurred, show current ammonia and oxygen, show reward when available, and link directly to the operator's recovered tank.
9. Rejected decisions shall explicitly state that no simulator mutation occurred.
10. A newly pending request shall clear an older local decision receipt so the new request cannot be hidden.
11. Producer controls shall remain absent from the operator tank and operator controls shall remain absent from the producer tank.
12. The workflow shall remain English, light, keyboard accessible, responsive, and compatible with the existing Sagents HITL resume path.

## Acceptance Criteria

1. Operator LiveView tests prove idle, pending, processing, approved, reduced, and rejected link states.
2. Producer LiveView tests prove the decision workspace precedes the tank and contains one control set.
3. Approval, half, and rejection tests prove a visible result receipt and correct mutation language.
4. Existing Sagents resume, queue race, producer isolation, simulator, and verifier tests pass.
5. Production assets, Docker smoke, and live-demo validation pass.

## Non-Goals

- This feature does not auto-approve actions or bypass the producer.
- It does not merge the operator and producer authorization roles.
- It does not add authentication, notifications, or a database.
