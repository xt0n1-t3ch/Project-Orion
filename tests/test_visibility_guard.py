import math
import unittest
from dataclasses import dataclass


@dataclass(frozen=True)
class VisibilityEvidence:
    reason: str
    trigger: str
    target: int
    count: int


@dataclass
class PairVisibilityState:
    hidden_ticks: int = 0
    last_checked_tick: int = -1
    is_visible: bool = True
    last_visible_at: float = 0.0


class VisibilityGuardMirror:
    def __init__(
        self,
        *,
        pvs_grace_seconds: float = 3.0,
        pvs_min_block_distance: float = 900.0,
        trace_budget_per_tick: int = 512,
        prefire_aim_dot_min: float = 0.995,
        prefire_min_events: int = 3,
        prefire_window_seconds: float = 20.0,
    ) -> None:
        self.pvs_grace_seconds = pvs_grace_seconds
        self.pvs_min_block_distance = pvs_min_block_distance
        self.trace_budget_per_tick = trace_budget_per_tick
        self.prefire_aim_dot_min = prefire_aim_dot_min
        self.prefire_min_events = prefire_min_events
        self.prefire_window_seconds = prefire_window_seconds
        self.pair_state: dict[tuple[int, int], PairVisibilityState] = {}
        self.prefire_count_by_survivor: dict[int, int] = {}
        self.prefire_window_started_at: dict[int, float] = {}
        self.trace_tick = -1
        self.trace_count = 0

    def record_prefire(
        self,
        *,
        survivor: int,
        infected: int,
        now: float,
        tick: int,
        aim_dot: float,
        has_line_of_sight: bool,
        distance: float,
        trigger: str = "weapon_fire",
    ) -> list[VisibilityEvidence]:
        if aim_dot < self.prefire_aim_dot_min:
            return []

        if not self.is_pvs_hidden_and_stale(
            survivor=survivor,
            infected=infected,
            now=now,
            tick=tick,
            has_line_of_sight=has_line_of_sight,
            distance=distance,
        ):
            return []

        window_started_at = self.prefire_window_started_at.get(survivor, 0.0)
        if window_started_at <= 0.0 or now - window_started_at > self.prefire_window_seconds:
            self.prefire_window_started_at[survivor] = now
            self.prefire_count_by_survivor[survivor] = 0

        self.prefire_count_by_survivor[survivor] += 1
        count = self.prefire_count_by_survivor[survivor]
        if count < self.prefire_min_events:
            return []

        return [
            VisibilityEvidence(
                reason="prefire_through_wall",
                trigger=trigger,
                target=infected,
                count=count,
            )
        ]

    def is_pvs_hidden_and_stale(
        self,
        *,
        survivor: int,
        infected: int,
        now: float,
        tick: int,
        has_line_of_sight: bool,
        distance: float,
    ) -> bool:
        is_hidden = self.should_block_pvs_transmit(
            entity=infected,
            observer=survivor,
            now=now,
            tick=tick,
            has_line_of_sight=has_line_of_sight,
            distance=distance,
        )
        if not is_hidden:
            return False

        state = self.pair_state[(infected, survivor)]
        return state.last_visible_at > 0.0 and now - state.last_visible_at > self.pvs_grace_seconds

    def should_block_pvs_transmit(
        self,
        *,
        entity: int,
        observer: int,
        now: float,
        tick: int,
        has_line_of_sight: bool,
        distance: float,
    ) -> bool:
        state = self.pair_state.setdefault((entity, observer), PairVisibilityState())
        if state.last_checked_tick == tick:
            return not state.is_visible

        state.last_checked_tick = tick
        if self.is_point_visible(tick=tick, has_line_of_sight=has_line_of_sight):
            state.is_visible = True
            state.hidden_ticks = 0
            state.last_visible_at = now
            return False

        state.hidden_ticks += 1
        if state.last_visible_at <= 0.0:
            state.last_visible_at = now
            return False

        if now - state.last_visible_at <= self.pvs_grace_seconds:
            return False

        if distance < self.pvs_min_block_distance:
            return False

        state.is_visible = False
        return True

    def is_point_visible(self, *, tick: int, has_line_of_sight: bool) -> bool:
        if self.trace_tick != tick:
            self.trace_tick = tick
            self.trace_count = 0

        if self.trace_count >= self.trace_budget_per_tick:
            return True

        self.trace_count += 1
        return has_line_of_sight


class VisibilityGuardMirrorTests(unittest.TestCase):
    def test_line_of_sight_enemy_is_not_prefire_evidence(self) -> None:
        guard = VisibilityGuardMirror(prefire_min_events=2)

        for event_index in range(3):
            evidence = guard.record_prefire(
                survivor=1,
                infected=2,
                now=10.0 + event_index,
                tick=100 + event_index,
                aim_dot=1.0,
                has_line_of_sight=True,
                distance=1200.0,
            )

            self.assertEqual(evidence, [])

    def test_recently_visible_hidden_enemy_stays_inside_grace_window(self) -> None:
        guard = VisibilityGuardMirror(pvs_grace_seconds=3.0, prefire_min_events=1)

        guard.should_block_pvs_transmit(
            entity=2,
            observer=1,
            now=10.0,
            tick=100,
            has_line_of_sight=True,
            distance=1200.0,
        )
        evidence = guard.record_prefire(
            survivor=1,
            infected=2,
            now=12.0,
            tick=101,
            aim_dot=1.0,
            has_line_of_sight=False,
            distance=1200.0,
        )

        self.assertEqual(evidence, [])

    def test_sustained_precise_fire_at_stale_pvs_hidden_enemy_flags_prefire(self) -> None:
        guard = VisibilityGuardMirror(prefire_min_events=3)

        self.assertFalse(
            guard.should_block_pvs_transmit(
                entity=2,
                observer=1,
                now=10.0,
                tick=100,
                has_line_of_sight=False,
                distance=1200.0,
            )
        )

        evidence: list[VisibilityEvidence] = []
        for event_index in range(3):
            evidence = guard.record_prefire(
                survivor=1,
                infected=2,
                now=14.0 + event_index,
                tick=101 + event_index,
                aim_dot=0.999,
                has_line_of_sight=False,
                distance=1200.0,
            )

        self.assertEqual(
            evidence,
            [
                VisibilityEvidence(
                    reason="prefire_through_wall",
                    trigger="weapon_fire",
                    target=2,
                    count=3,
                )
            ],
        )

    def test_trace_budget_fails_open_before_prefire_scoring(self) -> None:
        guard = VisibilityGuardMirror(trace_budget_per_tick=1, prefire_min_events=1)

        self.assertFalse(
            guard.should_block_pvs_transmit(
                entity=2,
                observer=1,
                now=10.0,
                tick=100,
                has_line_of_sight=False,
                distance=1200.0,
            )
        )
        evidence = guard.record_prefire(
            survivor=1,
            infected=3,
            now=14.0,
            tick=100,
            aim_dot=1.0,
            has_line_of_sight=False,
            distance=1200.0,
        )

        self.assertEqual(evidence, [])
        self.assertEqual(guard.trace_count, 1)

    def test_precise_aim_threshold_rejects_loose_crosshair_placement(self) -> None:
        guard = VisibilityGuardMirror(prefire_min_events=1)

        evidence = guard.record_prefire(
            survivor=1,
            infected=2,
            now=14.0,
            tick=101,
            aim_dot=math.cos(math.radians(8.0)),
            has_line_of_sight=False,
            distance=1200.0,
        )

        self.assertEqual(evidence, [])


if __name__ == "__main__":
    unittest.main()
