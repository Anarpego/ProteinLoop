from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/deploy_digitalocean_public.sh"


class DigitalOceanDeploySourceTests(unittest.TestCase):
    def test_deployment_is_isolated_and_registry_free(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")

        for marker in (
            "/opt/proteinloop/source",
            "/etc/proteinloop/public.env",
            "--project-name proteinloop",
            "PUBLIC_BIND_IP=127.0.0.1",
            "PUBLIC_PORT=${PROTEINLOOP_REMOTE_PORT}",
            "pull --ff-only origin main",
        ):
            self.assertIn(marker, source)

        self.assertNotIn("docker login", source)
        self.assertNotIn("docker push", source)

    def test_caddy_change_is_validated_and_existing_routes_are_preserved(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")

        self.assertIn('CADDY_BACKUP="${CADDYFILE}.bak.', source)
        self.assertIn('cp "${CADDYFILE}" "${CADDY_BACKUP}"', source)
        self.assertIn('cp "${CADDY_BACKUP}" "${CADDYFILE}"', source)
        self.assertIn('caddy validate --config "${CADDYFILE}"', source)
        self.assertIn("systemctl reload caddy", source)
        self.assertNotIn("cat >\"${CADDYFILE}\"", source)

    def test_secret_is_generated_on_server_and_not_echoed(self) -> None:
        source = SCRIPT.read_text(encoding="utf-8")

        self.assertIn("openssl rand -hex 64", source)
        self.assertIn("chmod 0600", source)
        self.assertNotIn("echo ${SECRET_KEY_BASE}", source)


if __name__ == "__main__":
    unittest.main()
