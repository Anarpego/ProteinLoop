# Feature Spec: Model Endpoint Status

## Goal

Make the OpenAI-compatible Gemma boundary visible in the operator dashboard so judges can see whether the project is configured for AMD-hosted vLLM or a Fireworks fallback.

## Functional Requirements

### FR-001: Configuration Snapshot

The app shall report whether `GEMMA_ENDPOINT` is configured and which `GEMMA_MODEL` value will be used.

### FR-002: Reachability Check

The operator dashboard shall provide a control that probes the configured endpoint at `/v1/models`.

### FR-003: Safe Failure

If the endpoint is missing, unreachable, or requires authentication, the dashboard shall show a clear status without interrupting the simulator, harness, or producer workflow.

## Acceptance Criteria

1. Unit tests cover unconfigured, reachable, auth-required, and unreachable endpoint statuses.
2. The operator dashboard renders model endpoint status and a check control.
3. No new dependency is added for this slice.
4. Python and Phoenix tests pass.
5. Docker Compose serves the updated dashboard.
