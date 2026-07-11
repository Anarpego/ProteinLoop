# Plan: CPU Gemma on the Public Host

1. Verify post-resize capacity and existing service health.
2. Pin and package the latest official Linux llama.cpp runtime.
3. Add an optional, private, resource-bounded Gemma Compose service.
4. Add a transactional deployment helper with model checksum and environment rollback.
5. Publish the implementation, deploy the model, and connect Phoenix after health checks.
6. Validate inference, public UX, resources, Kato, and write deployment evidence.

