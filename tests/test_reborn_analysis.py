from pathlib import Path
import tempfile
import unittest
import zipfile

from tools.analyze_reborn_trainer import analyze_trainer, render_markdown


class RebornAnalysisTests(unittest.TestCase):
    def test_analyzer_accounts_for_all_files_and_clusters_features(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "sample.dll").write_bytes(
                b"MZ"
                + b"\x00" * 128
                + b"Aimbot Perfect Silent Glow Chams Nospread Fakelag CreateRemoteThread"
            )
            (root / "readme.txt").write_text("use anti obs and bhop", encoding="utf-8")
            with zipfile.ZipFile(root / "dependencies.zip", "w") as archive:
                archive.writestr("libcef.dll", b"cef")

            reports = analyze_trainer(root)
            names = {report.name for report in reports}

            self.assertEqual(names, {"sample.dll", "readme.txt", "dependencies.zip"})
            markdown = render_markdown(reports, root)
            self.assertIn("Aimbot", markdown)
            self.assertIn("Glow", markdown)
            self.assertIn("dependencies.zip", markdown)


if __name__ == "__main__":
    unittest.main()
