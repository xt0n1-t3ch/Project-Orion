# Test Index

- `tests/test_docs_coverage.py`: verifies required threat model, runbook, research, and evidence schema docs exist and are non-trivial.
- `tests/test_orion_evidence_report.py`: verifies Orion evidence log parsing, grouping, redaction, and report output for calibration sessions.

Run:

```powershell
python -m unittest discover -s tests -p "test_*.py"
```
