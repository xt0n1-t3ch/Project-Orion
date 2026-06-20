import json
import subprocess
import sys
import tempfile
import unittest
from io import StringIO
from pathlib import Path

from scripts.orion_evidence_report import (
    group_orion_evidence,
    parse_orion_evidence_line,
    parse_orion_evidence_lines,
    write_csv_report,
    write_markdown_report,
)


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = ROOT / "scripts" / "orion_evidence_report.py"


class OrionEvidenceReportTests(unittest.TestCase):
    def test_parser_reads_session_tagged_source_mod_log_line(self) -> None:
        record = parse_orion_evidence_line(
            'L 06/20/2026 - 14:01:02: seq=12 session=reborn_silent type=aim score=82.5 '
            'action=observe client=Tony steamid=STEAM_1:1:123 name="Tony" map=c1m1_hotel '
            'mode=shadow details="reason=hurt_correlation target=5 angle_delta=42.0"'
        )

        self.assertIsNotNone(record)
        self.assertEqual(record.session, "reborn_silent")
        self.assertEqual(record.evidence_type, "aim")
        self.assertEqual(record.score, 82.5)
        self.assertEqual(record.details["reason"], "hurt_correlation")

    def test_grouping_summarizes_by_session_type_steamid_and_action(self) -> None:
        records = parse_orion_evidence_lines(
            [
                'seq=1 session=clean_scrim type=movement score=12.0 action=observe client=A steamid=STEAM_1:1:1 name="Clean" map=c1m1 mode=shadow details="reason=jump_window"',
                'seq=2 session=reborn_psilent type=aim score=91.0 action=ban client=B steamid=STEAM_1:1:2 name="Lab" map=c1m1 mode=shadow details="reason=death_correlation"',
                'seq=3 session=reborn_psilent type=aim score=96.0 action=ban client=B steamid=STEAM_1:1:2 name="Lab" map=c1m2 mode=shadow details="reason=autoshoot_death_correlation"',
            ]
        )

        groups = group_orion_evidence(records)

        self.assertEqual(groups[0].session, "reborn_psilent")
        self.assertEqual(groups[0].count, 2)
        self.assertEqual(groups[0].max_score, 96.0)
        self.assertEqual(groups[0].last_map_name, "c1m2")

    def test_report_writers_emit_machine_and_human_readable_outputs(self) -> None:
        records = parse_orion_evidence_lines(
            [
                'seq=1 session=reborn_bhop type=movement score=80.0 action=observe client=B steamid=STEAM_1:1:2 name="Lab" map=c1m1 mode=shadow details="reason=jump_window"',
            ]
        )
        groups = group_orion_evidence(records)

        markdown_output = StringIO()
        csv_output = StringIO()
        write_markdown_report(groups, markdown_output)
        write_csv_report(groups, csv_output)

        self.assertIn("| reborn_bhop | movement |", markdown_output.getvalue())
        self.assertIn("reborn_bhop,movement", csv_output.getvalue())

    def test_cli_exports_redacted_json_and_flat_csv_for_corpus_review(self) -> None:
        log_text = "\n".join(
            [
                'seq=1 type=aim score=10.0 action=observe client=1 steamid=STEAM_1:0:10 name="clean" map=c1m1_hotel mode=shadow details="reason=low"',
                'seq=2 type=aim score=91.0 action=ban client=2 steamid=STEAM_1:0:20 name="cheat" map=c1m1_hotel mode=shadow details="reason=silent"',
            ]
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            log_path = temp_path / "orion.log"
            json_path = temp_path / "corpus.json"
            csv_path = temp_path / "corpus.csv"
            log_path.write_text(log_text, encoding="utf-8")

            subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    str(log_path),
                    "--session-label",
                    "reborn-perfect-silent-lab",
                    "--min-score",
                    "50",
                    "--redact-steamids",
                    "--redaction-salt",
                    "test-salt",
                    "--json-out",
                    str(json_path),
                    "--csv-out",
                    str(csv_path),
                ],
                check=True,
                cwd=ROOT,
                capture_output=True,
                text=True,
            )

            summary = json.loads(json_path.read_text(encoding="utf-8"))
            csv_text = csv_path.read_text(encoding="utf-8")

        self.assertEqual(summary["schema_version"], "orion-corpus-v1")
        self.assertEqual(summary["session"]["label"], "reborn-perfect-silent-lab")
        self.assertEqual(summary["session"]["record_count"], 1)
        self.assertTrue(summary["players"][0]["steamid"].startswith("steamid_sha256:"))
        self.assertIn("reborn-perfect-silent-lab", csv_text)


if __name__ == "__main__":
    unittest.main()
