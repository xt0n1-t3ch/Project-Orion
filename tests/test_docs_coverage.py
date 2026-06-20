from pathlib import Path
import unittest


class DocumentationCoverageTests(unittest.TestCase):
    def test_required_docs_exist(self) -> None:
        root = Path(__file__).resolve().parents[1]
        required_docs = [
            root / "docs" / "ORION-THREAT-MODEL.md",
            root / "docs" / "ORION-ADMIN-RUNBOOK.md",
            root / "docs" / "research" / "reborn-trainer-analysis.md",
            root / "docs" / "research" / "l4d2-cheat-threat-intel.md",
            root / "docs" / "reference" / "evidence-schema.md",
        ]

        for doc_path in required_docs:
            self.assertTrue(doc_path.exists(), f"missing {doc_path}")
            self.assertGreater(len(doc_path.read_text(encoding="utf-8")), 500)


if __name__ == "__main__":
    unittest.main()
