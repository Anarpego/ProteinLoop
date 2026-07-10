# ProteinLoop Real Sagents Evidence

Generated from the live local Gemma OpenAI-compatible endpoint and Docker simulator.

## Runtime

- Sagents 0.9.0
- LangChain 0.9.2
- Model: google/gemma-4-E2B-it
- Distribution: local
- Execution mode: ProteinLoop.Agent.SafetyMode
- Termination: until_tool_success

## Verified Cycle

- Tool: close_cycle
- Final day: 1
- Reward: 203.7155
- Verifier accepted: true

## Subagents

- fish-tank: stable
- freshwater-prawn: stable
- hydroponia: stable
- duckweed-chickens: stable

## HumanInTheLoop

- Tool: irreversible_cycle
- Decisions: approve, edit, reject
- No mutation before approval: true
- Rejection resumed through Sagents: true
- No mutation after rejection: true

## Checks

- real_sagents_runtime: true
- four_subagents_completed: true
- real_sagents_subagents: true
- custom_safety_mode: true
- until_tool_success: true
- verification_accepted: true
- action_preserved: true
- hitl_interrupted_before_mutation: true
- hitl_reject_resumed_without_mutation: true
