from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COMPOSE = ROOT / "docker-compose.public.yml"
DOCKERFILE = ROOT / "deploy" / "gemma-cpu.Dockerfile"
SCRIPT = ROOT / "scripts" / "deploy_cpu_gemma.sh"
VALIDATOR = ROOT / "scripts" / "validate_gemma_endpoint.py"


class CpuGemmaDeploySourceTests(unittest.TestCase):
    def test_runtime_is_pinned_and_checksum_verified(self) -> None:
        source = DOCKERFILE.read_text(encoding="utf-8")

        self.assertIn("LLAMA_CPP_RELEASE=b9957", source)
        self.assertIn("ARG TARGETARCH", source)
        self.assertIn(
            "731a74cbb99783e8d4dc3a530e1a94fae3fa0960a57574b62926efde694dba94",
            source,
        )
        self.assertIn(
            "dc9e28f4a6e7c5bc9b22bd3669043c23cfe8f5af6428eada7f47de10e6923f34",
            source,
        )
        self.assertIn("sha256sum -c -", source)
        self.assertIn("USER llama", source)

    def test_compose_profile_is_private_and_resource_bounded(self) -> None:
        source = COMPOSE.read_text(encoding="utf-8")
        gemma = source.split("  gemma:", maxsplit=1)[1].split("  web:", maxsplit=1)[0]

        for marker in (
            'profiles: ["gemma-cpu"]',
            "mem_limit: 5g",
            'cpus: "3.0"',
            'GEMMA_CONTEXT_SIZE:-4096',
            'GEMMA_PARALLEL:-1',
            'GEMMA_BATCH_SIZE:-512',
            'GEMMA_UBATCH_SIZE:-256',
            "q8_0",
            "gemma-4-E2B_q4_0-it.gguf",
            "/models:ro",
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, gemma)

        self.assertNotIn("ports:", gemma)

    def test_deployment_verifies_model_before_transactional_web_update(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")

        for marker in (
            "3646b4c147cd235a44d91df1546d3b7d8e29b547dbe4e1f80856419aa455e6fd",
            "3349514112",
            "MEMORY_KIB < 7500000",
            "partial_is_valid",
            "--profile gemma-cpu",
            "GEMMA_ENDPOINT=http://gemma:8001/v1",
            "ENV_BACKUP=",
            "restore_environment",
            "kato-api-1",
            "kato-maptiles-maptiles-1",
            "kato-osrm-osrm-1",
            "docker cp scripts/validate_gemma_endpoint.py",
            "--endpoint http://gemma:8001/v1",
            'test "${CONFIGURED_GEMMA_ENDPOINT}" = "${TARGET_GEMMA_ENDPOINT}"',
            "cat > /tmp/proteinloop-deploy-cpu-gemma.sh",
            "bash /tmp/proteinloop-deploy-cpu-gemma.sh",
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, source)

        self.assertNotIn("docker system prune", source)
        self.assertNotIn("systemctl reload caddy", source)
        self.assertNotIn("docker exec -i proteinloop-simulator-1 python -", source)
        self.assertNotIn("bash -s", source)
        self.assertNotIn('| grep -Fq "Gemma 4 endpoint configured"', source)

        validator = VALIDATOR.read_text(encoding="utf-8")
        self.assertIn('join_url(endpoint, "/v1/models")', validator)
        self.assertIn('join_url(endpoint, "/v1/chat/completions")', validator)


if __name__ == "__main__":
    unittest.main()
