# Plan: DigitalOcean Public Deployment

1. Add configurable loopback binding to the public Compose profile.
2. Add and test an idempotent SSH deployment script based on the existing Kato/Caddy conventions.
3. Audit server capacity, containers, ports, and Caddy routes.
4. Build and start ProteinLoop as an isolated Compose project.
5. Add the ProteinLoop Caddy site, obtain TLS, and validate public routes.
6. Update submission URL artifacts and publish deployment evidence.

