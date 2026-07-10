import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.docker_smoke_test import Check, build_evidence


class DockerSmokeEvidenceTests(unittest.TestCase):
    def test_build_evidence_records_checks_and_urls(self):
        evidence = build_evidence(
            [
                Check("simulator health", True),
                Check("producer English route", True, "ok"),
            ]
        )

        self.assertTrue(evidence["ok"])
        self.assertEqual(evidence["checks"][0]["name"], "simulator health")
        self.assertIn("simulator_url", evidence)
        self.assertIn("web_url", evidence)

    def test_build_evidence_fails_when_any_check_fails(self):
        evidence = build_evidence([Check("operator dashboard route", False, "missing marker")])

        self.assertFalse(evidence["ok"])
        self.assertEqual(evidence["checks"][0]["detail"], "missing marker")


if __name__ == "__main__":
    unittest.main()
