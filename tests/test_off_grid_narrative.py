import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class OffGridNarrativeTests(unittest.TestCase):
    def test_readme_explains_local_acquisition_and_proof_boundaries(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")

        for marker in [
            "Why DECT NR+ Matters Off Grid",
            "Target Field Acquisition Path",
            "No Wi-Fi",
            "No cloud",
            "No electrical grid",
            "separate edge computer",
            "does **not yet** claim physical chemistry-probe acquisition",
        ]:
            self.assertIn(marker, readme)

        self.assertNotIn("nRF9151 runs Gemma", readme)

    def test_submission_copy_keeps_proven_and_planned_evidence_separate(self):
        submission = (ROOT / "submission/lablab-submission.md").read_text(encoding="utf-8")

        self.assertIn("DECT NR+ is the private, non-cellular 5G field link", submission)
        self.assertIn("Gemma does not run on either nRF9151 board", submission)
        self.assertIn("proves the physical two-board radio link and local Gemma runtime", submission)
        self.assertIn("labels chemistry probes, solar autonomy", submission)

    def test_video_and_deck_tell_the_same_off_grid_story(self):
        video = (ROOT / "submission/video-script.md").read_text(encoding="utf-8")
        deck = (ROOT / "scripts/generate_submission_deck.mjs").read_text(encoding="utf-8")

        self.assertIn("This local hop needs no Wi-Fi, SIM, or cloud account", video)
        self.assertIn("Physical probes and measured solar-plus-battery autonomy", video)
        self.assertIn("Private field radio keeps the food control loop local", deck)
        self.assertIn("Next measured field proof", deck)
        self.assertIn("public 8 GB CPU host", deck)
        self.assertIn("self-hosted CPU inference", video)


if __name__ == "__main__":
    unittest.main()
