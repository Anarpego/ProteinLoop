# ProteinLoop Mesh Evidence

Generated from the deterministic Elixir mesh model used by the operator dashboard.

## Summary

- Failed node: edge-tank-a.
- Migration count: 2.
- Failed node offline: true.
- Agents left failed node: true.
- State tokens preserved: true.
- Recovered node online: true.

## Migrated Agents

- Fish tank agent: edge-tank-a -> edge-tank-b; token fish-tank:state:v1; migrations 1.
- Hydroponia agent: edge-tank-a -> cloud-loop; token hydroponia:state:v1; migrations 1.

## Events

- After failure: 2 agents migrated from edge-tank-a | mesh initialized
- After recovery: edge-tank-a recovered and ready | 2 agents migrated from edge-tank-a | mesh initialized
