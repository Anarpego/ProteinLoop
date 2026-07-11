import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from scripts.validate_visual_evidence import analyze_region


class VisualEvidenceTests(unittest.TestCase):
    def test_analyze_region_rejects_flat_pixels(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "flat.png"
            Image.new("RGB", (100, 100), "#dff3f6").save(path)

            result = analyze_region(path, (0, 0, 100, 100))

        self.assertFalse(result["nonblank"])

    def test_analyze_region_accepts_varied_scene_pixels(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "scene.png"
            image = Image.new("RGB", (100, 100), "#dff3f6")
            draw = ImageDraw.Draw(image)
            draw.rectangle((10, 10, 45, 80), fill="#2f6f79")
            draw.ellipse((50, 20, 90, 65), fill="#d57932")
            image.save(path)

            result = analyze_region(path, (0, 0, 100, 100))

        self.assertTrue(result["nonblank"])
        self.assertGreater(result["sampled_colors"], 2)


if __name__ == "__main__":
    unittest.main()
