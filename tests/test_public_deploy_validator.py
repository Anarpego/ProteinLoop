import tempfile
import unittest
from pathlib import Path

from scripts.validate_public_deploy import validate_profile


class PublicDeployValidatorTests(unittest.TestCase):
    def test_validate_profile_rejects_missing_file(self):
        checks = validate_profile(Path("/tmp/does-not-exist-proteinloop-compose.yml"))

        self.assertFalse(checks[0][1])

    def test_validate_profile_rejects_public_simulator_port(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "docker-compose.public.yml"
            path.write_text(
                """
services:
  simulator:
    build: .
    restart: unless-stopped
    ports:
      - "8000:8000"
  web:
    restart: unless-stopped
                """,
                encoding="utf-8",
            )

            checks = validate_profile(path)

        self.assertTrue(any(name == "local-only settings absent" and not ok for name, ok, _detail in checks))


if __name__ == "__main__":
    unittest.main()
