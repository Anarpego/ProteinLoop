import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.validate_submission_readiness import extract_labeled_url, normalize_git_remote, url_check


class SubmissionReadinessTests(unittest.TestCase):
    def test_extract_labeled_url_rejects_todo(self):
        text = "Public GitHub Repository: TODO\nApplication URL: https://demo.example.com\n"

        self.assertIsNone(extract_labeled_url(text, "Public GitHub Repository"))
        self.assertEqual(extract_labeled_url(text, "Application URL"), "https://demo.example.com")

    def test_url_check_requires_github_host_for_repo(self):
        self.assertFalse(url_check("repo", "https://example.com/team/repo", required_host="github.com").ok)
        self.assertTrue(url_check("repo", "https://github.com/team/repo", required_host="github.com").ok)

    def test_normalize_git_remote_supports_https_and_ssh(self):
        self.assertEqual(
            normalize_git_remote("https://github.com/Team/ProteinLoop.git"),
            "github.com/team/proteinloop",
        )
        self.assertEqual(
            normalize_git_remote("git@github.com:Team/ProteinLoop.git"),
            "github.com/team/proteinloop",
        )


if __name__ == "__main__":
    unittest.main()
