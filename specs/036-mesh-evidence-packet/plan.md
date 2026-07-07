# Implementation Plan: Mesh Evidence Packet

## Scope

- Add `ProteinLoop.Agent.MeshEvidence`.
- Add an Elixir script that writes JSON and Markdown evidence files.
- Add `make mesh-evidence` and include it in `submission-render`.
- Add Elixir tests for the evidence contract.
- Include the evidence in bundle and submission validation.
- Update README and lablab submission copy.

## Verification

- Run `cd app && mix test test/proteinloop/agent/mesh_evidence_test.exs`.
- Run `make mesh-evidence`.
- Run `make submission-check`.
- Run `cd app && mix test`.
- Run `make test`.
