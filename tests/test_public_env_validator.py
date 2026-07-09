import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.validate_public_env import (
    Check,
    is_public_hostname,
    validate_env,
    validate_port,
    validate_secret_key_base,
    validate_simulator_url,
)


class PublicEnvValidatorTests(unittest.TestCase):
    def test_public_hostname_rejects_local_and_private_hosts(self):
        for host in ["localhost", "127.0.0.1", "10.0.0.2", "172.16.1.2", "192.168.1.2"]:
            with self.subTest(host=host):
                self.assertFalse(is_public_hostname(host))

        self.assertTrue(is_public_hostname("proteinloop.example.com"))

    def test_secret_key_base_rejects_missing_placeholder_or_short_value(self):
        self.assertFalse(validate_secret_key_base("").ok)
        self.assertFalse(validate_secret_key_base("replace-with-secret").ok)
        self.assertFalse(validate_secret_key_base("a" * 63).ok)
        self.assertTrue(validate_secret_key_base("a" * 64).ok)

    def test_port_validation(self):
        self.assertTrue(validate_port("").ok)
        self.assertTrue(validate_port("80").ok)
        self.assertTrue(validate_port("4000").ok)
        self.assertFalse(validate_port("0").ok)
        self.assertFalse(validate_port("70000").ok)
        self.assertFalse(validate_port("eighty").ok)

    def test_simulator_url_must_point_to_private_compose_service(self):
        self.assertTrue(validate_simulator_url("").ok)
        self.assertTrue(validate_simulator_url("http://simulator:8000").ok)
        self.assertFalse(validate_simulator_url("http://127.0.0.1:8000").ok)

    def test_validate_env_aggregates_checks(self):
        checks = validate_env(
            {
                "PHX_HOST": "proteinloop.example.com",
                "SECRET_KEY_BASE": "b" * 64,
                "PUBLIC_PORT": "443",
                "SIMULATOR_URL": "http://simulator:8000",
            }
        )

        self.assertTrue(all(isinstance(check, Check) for check in checks))
        self.assertTrue(all(check.ok for check in checks))


if __name__ == "__main__":
    unittest.main()
