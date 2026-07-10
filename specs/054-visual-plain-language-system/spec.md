# Feature Spec: Visual Plain-Language System

## Goal

Make ProteinLoop understandable to a first-time user without aquaculture knowledge. The interface must show the physical protein loop, identify the main tank, translate chemistry into everyday meaning, and keep the producer workflow entirely in English.

## User Value

A person can open either route and understand within seconds what the system contains, whether the animals can breathe, whether waste is becoming dangerous, what action is proposed, and which decision they can make.

## Functional Requirements

1. The operator route shall place a visual system scene near the top of the page, before analytics-heavy sections.
2. The scene shall visibly distinguish the main fish and prawn tank, hydroponic plants, duckweed reserve, and chicken/egg output.
3. Ammonia shall be introduced as `Waste in the water`, with the technical name and value shown secondarily.
4. Dissolved oxygen shall be introduced as `Air the animals can breathe`, with the technical name and value shown secondarily.
5. The scene shall derive stable, warning, and critical plain-language states from the existing deterministic thresholds.
6. The scene shall state what the current condition means for living animals and the immediate operational priority.
7. The producer route shall reuse a compact visual system scene instead of presenting raw chemistry cards as the primary content.
8. Every producer-facing heading, status, action, error, offline instruction, DECT note, and SMS/WhatsApp packet shall be English.
9. Approval-queue default prompts and rationales shall be English.
10. The app shall render in the light theme regardless of operating-system theme.
11. The DECT explanation shall continue to distinguish real radio evidence from simulated water chemistry.
12. No new frontend or model dependency shall be added.

## Acceptance Criteria

1. Component tests prove stable, warning, and critical states render distinct plain-language meaning.
2. Operator tests prove the visual system scene and plain-language chemistry labels are present.
3. Producer tests prove the visual scene, English decisions, English DECT copy, and English completion states are present.
4. Producer message and offline-rule tests prove English packets for routine and emergency cases.
5. Controller, Docker smoke, live-demo, and readiness contracts use the English producer route.
6. Phoenix, Python, Docker smoke, and submission artifact checks pass.
