import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.publish_public_repo import parse_repo, plan_commands, update_submission_repo_url


class PublishPublicRepoTests(unittest.TestCase):
    def test_parse_repo_builds_urls(self):
        repo = parse_repo("Anarpego/proteinloop")

        self.assertEqual(repo.url, "https://github.com/Anarpego/proteinloop")
        self.assertEqual(repo.clone_url, "https://github.com/Anarpego/proteinloop.git")

    def test_parse_repo_rejects_full_url(self):
        with self.assertRaises(ValueError):
            parse_repo("https://github.com/Anarpego/proteinloop")

    def test_plan_commands_creates_repo_when_origin_missing(self):
        commands = plan_commands(parse_repo("Anarpego/proteinloop"), has_origin=False)

        self.assertEqual(commands[0][:4], ["gh", "repo", "create", "Anarpego/proteinloop"])
        self.assertEqual(commands[-1], ["git", "push", "-u", "origin", "main"])

    def test_update_submission_repo_url_replaces_todo(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "lablab-submission.md"
            path.write_text("Public GitHub Repository: TODO\n", encoding="utf-8")

            update_submission_repo_url(path, "https://github.com/Anarpego/proteinloop")

            self.assertEqual(
                path.read_text(encoding="utf-8"),
                "Public GitHub Repository: https://github.com/Anarpego/proteinloop\n",
            )


if __name__ == "__main__":
    unittest.main()
