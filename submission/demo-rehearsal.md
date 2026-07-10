# ProteinLoop Demo Rehearsal

Generated from executable simulator behavior.

## reset

- Status: PASS.
- Detail: Stable starting state loaded.
- State: day 0, ammonia 0.35 mg/L, oxygen 6.8 mg/L, collapsed False.

## ammonia_spike

- Status: PASS.
- Detail: Critical ammonia scenario injected.
- State: day 0, ammonia 4.6 mg/L, oxygen 4.4 mg/L, collapsed False.

## unsafe_rejection

- Status: PASS.
- Detail: Overfeeding proposal rejected before simulator mutation.
- Violations: feed_kg 4.000 exceeds safe daily limit 0.508, feed must stay at or below 0.10 kg/day during critical ammonia.

## safe_recovery

- Status: PASS.
- Detail: Safety policy mutates state only after verifier acceptance.
- State: day 1, ammonia 2.7538 mg/L, oxygen 9.2 mg/L, collapsed False.
- Reward: 135.2741.

## rlvr_policy_search

- Status: PASS.
- Detail: Verifier-guided candidate search improves best reward.
- Search: best growth_biased improved reward by 2.7556 over 5 iterations.

## human_approval

- Status: PASS.
- Detail: Producer path asks for approval before irreversible water or harvest action.
- Copy: Approve | Apply half | Reject

## offline_guidance

- Status: PASS.
- Detail: Fallback producer guidance remains deterministic when model/cloud access is absent.
- Copy: Do not feed. Start maximum aeration, use a verified partial water change, and call the community technician.
