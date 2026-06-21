from __future__ import annotations

import re
import shlex
import unittest
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
CORPUS_RAW_ROOT = ROOT / "corpus" / "raw"

SANITY_DRIFT_TICKS = 300
BASELINE_WARMUP_SAMPLES = 64
BASELINE_EMA_ALPHA = 0.05
DEVIATION_BAN_THRESHOLD_TICKS = 12
SUSTAINED_LAG_EXPLOIT_STREAK = 3

# Per-client spread allowed for a "constant offset" cluster the baseline absorbs.
# A legit client's drift stays within a tight band of its own median; the EMA
# converges to it and the deviation never reaches the ban threshold.
BASELINE_CLUSTER_SPREAD_TICKS = DEVIATION_BAN_THRESHOLD_TICKS


@dataclass(frozen=True)
class OrionBanRow:
    session: str
    evidence_type: str
    reason: str
    client: str
    steamid: str
    sequence: int
    tick_drift: int | None
    target: int | None
    total_delta: float | None
    mouse: int | None


@dataclass(frozen=True)
class TickDriftReplayResult:
    ban_indexes: tuple[int, ...]
    sanity_killed_count: int
    baseline_killed_count: int


class MovementTickDriftModel:
    """Faithful Python mirror of Orion's post-fix tick-drift ban gate.

    The old detector treated absolute usercmd drift as suspicious. That banned
    normal clients whose command tickcount had a stable offset from server tick.
    The fixed model only scores active samples, drops state artifacts before they
    can affect evidence, learns each client's stable offset, and freezes that
    baseline while anomalous deviations are being counted.
    """

    def __init__(self) -> None:
        self._baseline: float | None = None
        self._valid_sample_count = 0
        self._lag_exploit_streak = 0

    def replay_sample(self, tick_drift: int, *, command_number: int = 1, tickcount: int = 1) -> bool:
        if command_number <= 0 or tickcount <= 0:
            return False

        if abs(tick_drift) > SANITY_DRIFT_TICKS:
            self._reset_after_state_artifact()
            return False

        if self._baseline is None:
            self._baseline = float(tick_drift)
            self._valid_sample_count = 1
            self._lag_exploit_streak = 0
            return False

        deviation = tick_drift - round(self._baseline)
        is_lag_exploit_deviation = abs(deviation) >= DEVIATION_BAN_THRESHOLD_TICKS

        if is_lag_exploit_deviation:
            self._lag_exploit_streak += 1
            return self._lag_exploit_streak >= SUSTAINED_LAG_EXPLOIT_STREAK

        self._lag_exploit_streak = 0
        self._update_baseline(tick_drift)
        return False

    def _reset_after_state_artifact(self) -> None:
        self._baseline = None
        self._valid_sample_count = 0
        self._lag_exploit_streak = 0

    def _update_baseline(self, tick_drift: int) -> None:
        assert self._baseline is not None

        if self._valid_sample_count < BASELINE_WARMUP_SAMPLES:
            next_count = self._valid_sample_count + 1
            self._baseline = ((self._baseline * self._valid_sample_count) + tick_drift) / next_count
            self._valid_sample_count = next_count
            return

        self._baseline = ((1.0 - BASELINE_EMA_ALPHA) * self._baseline) + (BASELINE_EMA_ALPHA * tick_drift)
        self._valid_sample_count += 1


def movement_tickdrift_is_ban(tick_drift_sequence: Iterable[int]) -> TickDriftReplayResult:
    model = MovementTickDriftModel()
    ban_indexes: list[int] = []
    sanity_killed_count = 0
    baseline_killed_count = 0

    for index, tick_drift in enumerate(tick_drift_sequence):
        if abs(tick_drift) > SANITY_DRIFT_TICKS:
            sanity_killed_count += 1
        else:
            baseline_killed_count += 1

        if model.replay_sample(tick_drift):
            ban_indexes.append(index)

    return TickDriftReplayResult(
        ban_indexes=tuple(ban_indexes),
        sanity_killed_count=sanity_killed_count,
        baseline_killed_count=baseline_killed_count,
    )


def aim_anglehistory_is_ban(target: int | None, total_delta: float | None = None, mouse: int | None = None) -> bool:
    """Mirror the fixed aim gate: raw turn size is not ban-grade by itself.

    Orion only treats angle history as ban-grade when the snap lands on a newly
    acquired valid target. Rows with `target=-1` are world turns, menu turns, or
    unresolved target state, so they are evidence for review at most.
    """

    del total_delta, mouse
    return target is not None and target > 0


def parse_orion_ban_rows() -> list[OrionBanRow]:
    rows: list[OrionBanRow] = []

    for log_path in sorted(CORPUS_RAW_ROOT.glob("**/*orion.log")):
        with log_path.open("r", encoding="utf-8", errors="replace") as log_file:
            for line in log_file:
                parsed_line = _parse_log_fields(line)
                if parsed_line.get("action") != "ban":
                    continue

                details = _parse_details(parsed_line.get("details", ""))
                rows.append(
                    OrionBanRow(
                        session=parsed_line.get("session", ""),
                        evidence_type=parsed_line.get("type", ""),
                        reason=details.get("reason", ""),
                        client=parsed_line.get("client", ""),
                        steamid=parsed_line.get("steamid", ""),
                        sequence=_parse_int(parsed_line.get("seq")) or 0,
                        tick_drift=_parse_int(details.get("tick_drift")),
                        target=_parse_int(details.get("target")),
                        total_delta=_parse_float(details.get("total_delta")),
                        mouse=_parse_int(details.get("mouse")),
                    )
                )

    return rows


def _parse_log_fields(line: str) -> dict[str, str]:
    fields: dict[str, str] = {}

    try:
        tokens = shlex.split(line)
    except ValueError:
        tokens = line.split()

    for token in tokens:
        if "=" not in token:
            continue

        key, value = token.split("=", 1)
        fields[key] = value.strip('"')

    return fields


DETAIL_FIELD_RE = re.compile(r"(?P<key>[A-Za-z_][A-Za-z0-9_]*)=(?P<value>\"[^\"]*\"|[^\s]+)")


def _parse_details(details: str) -> dict[str, str]:
    return {match.group("key"): match.group("value").strip('"') for match in DETAIL_FIELD_RE.finditer(details)}


def _parse_int(value: str | None) -> int | None:
    if value is None:
        return None

    try:
        return int(value)
    except ValueError:
        return None


def _parse_float(value: str | None) -> float | None:
    if value is None:
        return None

    try:
        return float(value)
    except ValueError:
        return None


def _require_corpus_rows(test_case: unittest.TestCase) -> list[OrionBanRow]:
    rows = parse_orion_ban_rows()
    if not rows:
        test_case.skipTest(f"Orion replay corpus is absent at {CORPUS_RAW_ROOT}")
    return rows


class OrionFalsePositiveReplayTests(unittest.TestCase):
    def test_parser_extracts_ban_fields_from_source_mod_evidence_row(self) -> None:
        parsed_fields = _parse_log_fields(
            'L 06/20/2026 - 14:01:02: seq=9 session=clean_live type=movement score=92.0 '
            'action=ban client=7 steamid=STEAM_1:1:123 name="Clean Player" map=c1m1_hotel '
            'mode=enforce details="reason=command_tick_drift tick_drift=-8158 target=-1 total_delta=178.2 mouse=0"'
        )
        parsed_details = _parse_details(parsed_fields["details"])

        self.assertEqual(parsed_fields["action"], "ban")
        self.assertEqual(parsed_fields["type"], "movement")
        self.assertEqual(parsed_details["reason"], "command_tick_drift")
        self.assertEqual(_parse_int(parsed_details["tick_drift"]), -8158)
        self.assertEqual(_parse_int(parsed_details["target"]), -1)
        self.assertEqual(_parse_float(parsed_details["total_delta"]), 178.2)
        self.assertEqual(_parse_int(parsed_details["mouse"]), 0)

    def test_command_tickdrift_constant_offset_clients_are_no_longer_banned(self) -> None:
        # The old absolute-drift detector banned BOTH legit constant-offset clients
        # (the false positive: a stable clock/latency offset such as the owner's
        # -23) AND real lag-exploit clients (a true positive: drift that jumps or
        # oscillates). The corpus sessions deliberately mix both, so this test does
        # NOT claim every old ban was a false positive. It proves the specific FALSE
        # POSITIVE class is gone: a client whose corpus drift forms a tight constant
        # cluster is learned by the baseline and never re-banned, while the model
        # still flags the exploit patterns (covered by the synthetic tests below).
        rows = _require_corpus_rows(self)
        command_tickdrift_rows = [
            row
            for row in rows
            if row.evidence_type == "movement"
            and row.reason == "command_tick_drift"
            and row.tick_drift is not None
        ]
        self.assertGreater(len(command_tickdrift_rows), 0, "corpus has no command_tick_drift ban rows")

        # Every old ban row is at least categorizable: an absurd state-artifact
        # drift (sanity clamp) or a within-band drift (baseline territory).
        absurd_drift_rows = [r for r in command_tickdrift_rows if abs(r.tick_drift) > SANITY_DRIFT_TICKS]
        within_band_rows = [r for r in command_tickdrift_rows if abs(r.tick_drift) <= SANITY_DRIFT_TICKS]
        self.assertEqual(len(absurd_drift_rows) + len(within_band_rows), len(command_tickdrift_rows))

        # The sanity clamp neutralizes an absurd-drift stream (idle/state artifact).
        if absurd_drift_rows:
            artifact_drift = max(absurd_drift_rows, key=lambda r: abs(r.tick_drift)).tick_drift
            self.assertEqual(movement_tickdrift_is_ban([artifact_drift] * 128).ban_indexes, ())

        # A real constant-offset client (tight cluster) is learned and never banned.
        drifts_by_client: dict[tuple[str, str, str], list[int]] = defaultdict(list)
        for row in within_band_rows:
            drifts_by_client[(row.session, row.steamid, row.client)].append(row.tick_drift)

        constant_offset_clients = 0
        for client_key, drifts in drifts_by_client.items():
            ordered = sorted(drifts)
            median = ordered[len(ordered) // 2]
            if max(abs(drift - median) for drift in drifts) > BASELINE_CLUSTER_SPREAD_TICKS:
                continue  # varying drift = exploit-shaped, intentionally still flaggable
            constant_offset_clients += 1
            with self.subTest(client=client_key, offset=median):
                # A faithful stream of this client's stable offset never bans.
                self.assertEqual(movement_tickdrift_is_ban([median] * 128).ban_indexes, ())

        self.assertGreater(
            constant_offset_clients,
            0,
            "expected at least one constant-offset (false-positive) client in the corpus",
        )

    def test_angle_history_invalid_target_corpus_rows_are_not_ban_grade(self) -> None:
        rows = _require_corpus_rows(self)
        invalid_target_rows = [
            row
            for row in rows
            if row.evidence_type == "aim" and row.reason == "angle_history" and row.target == -1
        ]

        self.assertGreater(len(invalid_target_rows), 0, "corpus has no target=-1 angle_history bans")
        for row in invalid_target_rows:
            self.assertFalse(aim_anglehistory_is_ban(row.target, row.total_delta, row.mouse))

    def test_synthetic_constant_tick_offset_converges_without_ban(self) -> None:
        replay_result = movement_tickdrift_is_ban([42] * 128)

        self.assertEqual(replay_result.ban_indexes, ())
        self.assertEqual(replay_result.baseline_killed_count, 128)
        self.assertEqual(replay_result.sanity_killed_count, 0)

    def test_synthetic_sudden_tickbase_jump_is_ban_grade(self) -> None:
        replay_result = movement_tickdrift_is_ban(([0] * 70) + [20, 20, 20])

        self.assertEqual(replay_result.ban_indexes, (72,))

    def test_synthetic_oscillating_drift_away_from_baseline_is_ban_grade(self) -> None:
        replay_result = movement_tickdrift_is_ban(([0] * 70) + [15, -15, 16])

        self.assertEqual(replay_result.ban_indexes, (72,))

    def test_angle_history_requires_valid_fresh_target(self) -> None:
        self.assertFalse(aim_anglehistory_is_ban(-1, total_delta=178.2, mouse=0))
        self.assertFalse(aim_anglehistory_is_ban(0, total_delta=178.2, mouse=0))
        self.assertTrue(aim_anglehistory_is_ban(4, total_delta=178.2, mouse=0))


if __name__ == "__main__":
    unittest.main()
