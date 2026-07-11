from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COMPOSE = ROOT / "docker-compose.public.yml"
DOCKERFILE = ROOT / "deploy" / "gemma-cpu.Dockerfile"
SCRIPT = ROOT / "scripts" / "deploy_cpu_gemma.sh"


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
            "8827aa12e1b1b82f55a4e41e2939dbcf7dc3895a15278c1a6b610b137ca0d83f",
            "3349514112",
            "--profile gemma-cpu",
            "http://gemma:8001/v1/models",
            "http://gemma:8001/v1/chat/completions",
            "GEMMA_ENDPOINT=http://gemma:8001/v1",
            "ENV_BACKUP=",
            "restore_environment",
            "kato-api-1",
            "kato-maptiles-maptiles-1",
            "kato-osrm-osrm-1",
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, source)

        self.assertNotIn("docker system prune", source)
        self.assertNotIn("systemctl reload caddy", source)


if __name__ == "__main__":
    unittest.main()
