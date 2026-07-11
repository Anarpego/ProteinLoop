# Feature Spec: DigitalOcean Public Deployment

## Goal

Deploy the verified ProteinLoop demo to an existing shared DigitalOcean server without a container
registry, without exposing the simulator, and without disrupting existing services.

## User Value

Judges receive a stable HTTPS application URL before the submission deadline, while the deployment
remains reproducible from the public GitHub repository.

## Functional Requirements

1. The public Compose profile shall support binding Phoenix to a configurable host address.
2. Production deployment shall bind Phoenix to loopback and expose it only through the existing
   Caddy reverse proxy.
3. The simulator shall remain private on the Compose network.
4. The deployment shall use an isolated Compose project, deployment directory, environment file,
   and persistent trace volume.
5. The deployment shall clone or fast-forward the public GitHub repository and build native images
   on the target server; a private registry shall not be required.
6. The deployment shall preserve existing Caddy routes and validate configuration before reload.
7. Production secrets shall be generated on the server, stored outside the repository, and never
   printed.
8. The deployment shall verify the local container route and public HTTPS operator/producer routes.
9. The deployment shall not claim AMD-hosted inference when `GEMMA_ENDPOINT` is unavailable.

## Acceptance Criteria

1. Public-deploy source tests prove loopback binding, isolated paths, Compose project naming, Caddy
   validation, and server-side secret generation.
2. `make public-deploy-check` and `make public-env-check` pass for the deployment configuration.
3. Existing Phoenix and Python tests pass.
4. The remote Compose project reports healthy running services without changing Kato containers.
5. `make live-demo-check` passes against the final HTTPS URL.
6. The LabLab form and readiness artifacts contain the verified public URL.

