import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.publish_public_repo import (
    gh_auth_required,
    normalize_git_remote,
    parse_repo,
    plan_commands,
    update_submission_repo_url,
)


class PublishPublicRepoTests(unittest.TestCase):
    def test_parse_repo_builds_urls(self):
        repo = parse_repo("Anarpego/proteinloop")

        self.assertEqual(repo.url, "https://github.com/Anarpego/proteinloop")
        self.assertEqual(repo.clone_url, "https://github.com/Anarpego/proteinloop.git")

    def test_parse_repo_rejects_full_url(self):
        with self.assertRaises(ValueError):
            parse_repo("https://github.com/Anarpego/proteinloop")

    def test_plan_commands_creates_repo_when_origin_missing(self):
        commands = plan_commands(parse_repo("Anarpego/proteinloop"), has_origin=False, existing=False)

        self.assertEqual(commands[0][:4], ["gh", "repo", "create", "Anarpego/proteinloop"])
        self.assertEqual(commands[-1], ["git", "push", "-u", "origin", "main"])

    def test_plan_commands_uses_existing_repo_without_gh_create(self):
        commands = plan_commands(parse_repo("Anarpego/proteinloop"), has_origin=False, existing=True)

        self.assertEqual(
            commands,
            [
                ["git", "remote", "add", "origin", "https://github.com/Anarpego/proteinloop.git"],
                ["git", "push", "-u", "origin", "main"],
            ],
        )

    def test_plan_commands_accepts_custom_existing_remote_url(self):
        commands = plan_commands(
            parse_repo("Anarpego/proteinloop"),
            has_origin=False,
            existing=True,
            remote_url="git@github.com:Anarpego/proteinloop.git",
        )

        self.assertEqual(commands[0], ["git", "remote", "add", "origin", "git@github.com:Anarpego/proteinloop.git"])

    def test_plan_commands_accepts_matching_existing_https_origin(self):
        commands = plan_commands(
            parse_repo("Anarpego/proteinloop"),
            has_origin=True,
            origin_url="https://github.com/Anarpego/proteinloop.git",
        )

        self.assertEqual(commands, [["git", "push", "-u", "origin", "main"]])

    def test_plan_commands_accepts_matching_existing_ssh_origin(self):
        commands = plan_commands(
            parse_repo("Anarpego/proteinloop"),
            has_origin=True,
            origin_url="git@github.com:Anarpego/proteinloop.git",
        )

        self.assertEqual(commands, [["git", "push", "-u", "origin", "main"]])

    def test_plan_commands_rejects_mismatched_existing_origin(self):
        with self.assertRaises(ValueError):
            plan_commands(
                parse_repo("Anarpego/proteinloop"),
                has_origin=True,
                origin_url="https://github.com/other/project.git",
            )

    def test_normalize_git_remote_supports_https_and_ssh(self):
        self.assertEqual(
            normalize_git_remote("https://github.com/Anarpego/proteinloop.git"),
            "github.com/anarpego/proteinloop",
        )
        self.assertEqual(
            normalize_git_remote("git@github.com:Anarpego/proteinloop.git"),
            "github.com/anarpego/proteinloop",
        )

    def test_existing_repo_mode_does_not_require_gh_auth(self):
        create_commands = plan_commands(parse_repo("Anarpego/proteinloop"), has_origin=False, existing=False)
        existing_commands = plan_commands(parse_repo("Anarpego/proteinloop"), has_origin=False, existing=True)

        self.assertTrue(gh_auth_required(create_commands))
        self.assertFalse(gh_auth_required(existing_commands))

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
