# Feature Spec: Real Sagents Horde Failover

## Goal

Replace the local mesh-only evidence gap with an executable two-node Sagents/Horde deployment that moves a managed agent to a surviving BEAM node without losing its persisted state.

## Functional Requirements

1. The application shall support runtime selection between local Sagents distribution and Horde distribution without changing application code.
2. Horde mode shall use Sagents 0.9 participation-scoped membership so only nodes running `Sagents.Supervisor` host agents.
3. Agent state shall be persisted in JSON-compatible form on storage shared by both Docker nodes and restored through the `Sagents.AgentPersistence` behaviour.
4. A real `Sagents.AgentServer` shall run under `Sagents.AgentsDynamicSupervisor`, execute a verifier-gated Gemma cycle, and persist the completed state.
5. A two-node Docker profile shall connect named BEAM nodes with a shared cookie, shared persistence volume, simulator access, and local Gemma access.
6. The failover verifier shall stop the node that owns the managed agent, wait for Horde to place it on the surviving node, and prove that the state token and canonical state fingerprint are unchanged.
7. The verifier shall restart the stopped node, leave the cluster healthy, and write JSON and Markdown evidence suitable for the submission bundle.
8. The ordinary single-node Docker workflow shall remain local by default.

## Acceptance Criteria

1. Unit tests prove atomic persistence, state loading, invalid-file handling, and path isolation.
2. Phoenix tests prove Horde probe startup delegates to `Sagents.AgentsDynamicSupervisor` and reports a stable state fingerprint.
3. Both Docker nodes report Horde participation and see the same connected-node set.
4. Before and after failover snapshots identify different owner nodes for the same agent ID.
5. Before and after snapshots contain the same state token and canonical state fingerprint.
6. Restored persistence metadata proves at least one state load on the surviving node.
7. Existing Python, Phoenix, Docker smoke, and submission artifact checks continue to pass.
