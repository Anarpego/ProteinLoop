from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUNBOOK = ROOT / "deploy" / "digitalocean-uninstall.md"


class DigitalOceanUninstallRunbookTests(unittest.TestCase):
    def test_shell_examples_are_syntactically_valid_without_execution(self) -> None:
        text = RUNBOOK.read_text(encoding="utf-8")
        blocks = re.findall(r"```sh\n(.*?)\n```", text, flags=re.DOTALL)

        self.assertTrue(blocks)
        for index, block in enumerate(blocks):
            with self.subTest(block=index):
                result = subprocess.run(
                    ["bash", "-n"],
                    input=block,
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_runbook_scopes_every_removal_to_proteinloop(self) -> None:
        text = RUNBOOK.read_text(encoding="utf-8")

        for marker in (
            "--project-name proteinloop",
            "/opt/proteinloop/source/docker-compose.public.yml",
            "/etc/proteinloop/public.env",
            "proteinloop_proteinloop_traces",
            "proteinloop-web:latest",
            "proteinloop-simulator:latest",
            "proteinloop-gemma:latest",
            "/opt/proteinloop/models/gemma-4-E2B_q4_0-it.gguf",
            "--profile gemma-cpu",
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, text)

    def test_runbook_protects_caddy_and_kato(self) -> None:
        text = RUNBOOK.read_text(encoding="utf-8")

        for marker in (
            "CADDY_BACKUP",
            'caddy validate --config "${CADDYFILE}"',
            "systemctl reload caddy",
            "kato-api-1",
            "kato-maptiles-maptiles-1",
            "kato-osrm-osrm-1",
            "Rollback",
        ):
            with self.subTest(marker=marker):
                self.assertIn(marker, text)

        self.assertNotIn("rm -rf /opt/kato", text)

    def test_runbook_never_executes_global_docker_pruning(self) -> None:
        text = RUNBOOK.read_text(encoding="utf-8")

        for command in (
            "docker system prune",
            "docker volume prune",
            "docker image prune",
            "docker builder prune",
        ):
            with self.subTest(command=command):
                self.assertNotIn(f"\n{command}", text)


if __name__ == "__main__":
    unittest.main()
