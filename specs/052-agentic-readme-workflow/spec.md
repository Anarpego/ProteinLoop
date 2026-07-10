# Feature Spec: Agentic README Workflow

## Goal

Replace the README's chronological implementation log and flat specification inventory with a concise, GitHub-native explanation of the running system and its spec-driven agentic development loop.

## User Value

Repository visitors can understand what ProteinLoop does, where agents are allowed to act, how changes are developed, and which executable artifacts prove each claim without reading dozens of historical slice descriptions.

## Functional Requirements

1. The first README viewport shall identify ProteinLoop, show a repository-owned visual, and link to the main run, workflow, and evidence sections.
2. The README shall distinguish the product execution workflow from the software development workflow.
3. The product workflow shall show physical DECT evidence, simulator state, Gemma/Sagents proposals, deterministic verification, Spanish HITL, mutation, and trace evidence.
4. The development workflow shall show constitution, spec, plan, failing test, implementation, verification, review, and versioned evidence.
5. Current capabilities shall be summarized by executable proof rather than by implementation chronology.
6. GitHub Mermaid diagrams shall use short labels that remain readable in light and dark themes.
7. The complete spec system shall remain discoverable through links to the constitution, `AGENTS.md`, and `specs/`.
8. Existing run, test, deployment, and submission commands shall remain available below the redesigned workflow.
9. The README shall not claim that Nordic `hello_dect` contains chemical sensor readings or that local Gemma is AMD-hosted.

## Acceptance Criteria

1. The old `## Workflow` flat list and numbered slice narrative are removed.
2. `## System Workflow` and `## Agentic Development Workflow` render as valid Mermaid flowcharts on GitHub.
3. A new evidence table links directly to the simulator, Sagents, Horde, Gemma, DECT, and Docker proof artifacts.
4. The README still links to the test and demo instructions.
5. Markdown links introduced by this feature resolve to files or headings in the repository.
