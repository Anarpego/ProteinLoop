# Feature Spec: Protein-First Judge Story

## Goal

Make the operator experience explain ProteinLoop's food-security value within five seconds: aquaponics already connects fish and plants, while ProteinLoop protects the animal-protein side of that system, extends it to prawns and eggs, and verifies every AI recovery before it changes the living loop.

## User Value

A producer, judge, or first-time visitor can immediately understand what food is being protected, why a water emergency matters, how each organism supports the next output, and why the Agentic AI workflow is safer than an opaque automation button.

## Product Position

Aquaponics is an integrated fish-and-plant system. ProteinLoop does not claim to invent protein production in aquaponics. It makes the protein outcome measurable and recoverable, coordinates fish, freshwater prawns, plants, duckweed feed, chickens, and eggs, and keeps irreversible actions under producer control.

## Functional Requirements

1. The operator first viewport shall lead with the literal outcome "Protect every protein output in the loop" rather than a generic system-control title.
2. Supporting copy shall accurately state that aquaponics already links fish and plants and that ProteinLoop extends and protects the animal-protein side through prawns, duckweed feed, and eggs.
3. A connected-loop strip shall expose live values for fish and prawn biomass, plant biomass, duckweed reserve, chickens, and tracked eggs.
4. The tank shall show total fish-and-prawn biomass and a clear species breakdown; it shall not label total animal mass as pure protein mass.
5. Warning and critical tank states shall quantify the fish-and-prawn biomass depending on recovery.
6. Emergency injection shall be visibly identified as demo mode and use the explicit command "Inject demo water emergency".
7. The immersive Agentic AI console shall use outcome language: verified recovery, ecosystem safety check, producer control, and a safe recovery plan.
8. The console shall explain the trust boundary in one sentence: Gemma proposes, ecosystem rules verify, and the producer controls irreversible actions.
9. A completed mission shall show a judge-readable recovery receipt with ammonia and oxygen before/after values, verifier status, zero unsafe actions executed when accepted, and the protected fish-and-prawn outcome.
10. Detailed specialist traces and infrastructure evidence shall remain available below the primary story without competing with it.
11. Producer permissions shall remain unchanged, and all visible product copy shall remain English.
12. The light interface shall remain responsive and free of overlap in normal and full-screen desktop and mobile layouts.

## Acceptance Criteria

1. Component tests prove the biomass total, species breakdown, quantified risk, and demo-mode command.
2. Operator LiveView tests prove the protein-first purpose, connected-loop values, plain-language recovery workflow, and trust statement.
3. Mission tests prove the immersive receipt exposes chemistry before/after values and the accepted verifier outcome.
4. Existing producer authorization, simulator, verifier, harness, LiveView, and JavaScript regression tests continue to pass.
5. Production assets compile and the Docker live-demo validation passes.
6. Browser checks at desktop and mobile sizes show readable first-viewport hierarchy, nonblank tank pixels, and controls without overlap.

## Non-Goals

- This feature does not claim that conventional aquaponics excludes fish or protein.
- It does not estimate meals, nutrition, harvest yield, or mortality avoided without a validated domain model.
- It does not add a second agent runtime, simulator, database, or analytics framework.
- It does not expose chain-of-thought or bypass deterministic verification.

## Domain References

- USDA National Agricultural Library, Aquaculture and Aquaponics: https://www.nal.usda.gov/farms-and-agricultural-production-systems/aquaculture-and-aquaponics
- FAO, Small-scale aquaponic food production: https://www.fao.org/family-farming/detail/en/c/1743023/
