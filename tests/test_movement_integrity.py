from __future__ import annotations

import math
import unittest
from dataclasses import dataclass


TICKRATE = 30
TICK_INTERVAL = 1.0 / TICKRATE
BASELINE_WARMUP_SAMPLES = 64
BASELINE_ALPHA = 0.05
TICKBASE_DEVIATION_TOLERANCE_TICKS = 6
TICKBASE_DEVIATION_STREAK_MIN = 3
COMMAND_RATE_WINDOW_SECONDS = 1.0
COMMAND_RATE_ALLOWANCE_TICKS = 6
TICKBASE_RATE_ALLOWANCE_TICKS = 4
BACKTRACK_HIT_WINDOW_TICKS = 4
FORWARDTRACK_TOLERANCE_TICKS = 8
TELEPORT_MIN_HORIZONTAL_UNITS = 400.0
TELEPORT_MAX_SPEED_UPS = 350.0
TELEPORT_ALLOWANCE_MULTIPLIER = 4.0
FAKE_ANGLE_MIN_SPEED_UPS = 140.0
FAKE_ANGLE_TOLERANCE_DEGREES = 65.0
FAKE_ANGLE_STREAK_TICKS = 8


def normalize_angle_delta(angle_delta: float) -> float:
    while angle_delta > 180.0:
        angle_delta -= 360.0
    while angle_delta < -180.0:
        angle_delta += 360.0
    return abs(angle_delta)


class TickbaseDeviationModel:
    """Python mirror of the strengthened tickbase-vs-latency baseline gate."""

    def __init__(self) -> None:
        self.baseline = 0.0
        self.samples = 0
        self.deviation_streak = 0

    def sample(self, *, server_tick: int, latency_ticks: int, tickbase: int) -> bool:
        expected_tickbase = server_tick - latency_ticks
        drift = tickbase - expected_tickbase

        if self.samples < BASELINE_WARMUP_SAMPLES:
            self.baseline = ((self.baseline * self.samples) + drift) / (self.samples + 1)
            self.samples += 1
            return False

        deviation = drift - round(self.baseline)
        if abs(deviation) <= TICKBASE_DEVIATION_TOLERANCE_TICKS:
            self.baseline += BASELINE_ALPHA * (drift - self.baseline)
            self.deviation_streak = max(0, self.deviation_streak - 1)
            return False

        self.deviation_streak += 1
        return self.deviation_streak >= TICKBASE_DEVIATION_STREAK_MIN


class BacktrackHitModel:
    """Backtrack/forwardtrack is only ban-grade when the tick shift hits."""

    def __init__(self) -> None:
        self.last_shift_tick: int | None = None
        self.last_delta = 0
        self.hit_streak = 0

    def command(self, *, game_tick: int, previous_tickcount: int, tickcount: int) -> bool:
        tick_delta = tickcount - previous_tickcount
        if tick_delta < 0 or tick_delta > FORWARDTRACK_TOLERANCE_TICKS:
            self.last_shift_tick = game_tick
            self.last_delta = tick_delta
        return False

    def hurt(self, *, game_tick: int) -> bool:
        if self.last_shift_tick is None:
            return False
        if game_tick - self.last_shift_tick > BACKTRACK_HIT_WINDOW_TICKS:
            self.hit_streak = max(0, self.hit_streak - 1)
            return False
        self.hit_streak += 1
        return True


@dataclass
class SpeedWindow:
    commands: int
    elapsed_seconds: float
    elapsed_server_ticks: int
    tickbase_advance: int
    choke_allowance_ticks: int = 0
    loss_allowance_ticks: int = 0


def is_speed_command_rate(window: SpeedWindow) -> bool:
    network_allowance = (
        COMMAND_RATE_ALLOWANCE_TICKS
        + min(window.choke_allowance_ticks, 10)
        + min(window.loss_allowance_ticks, 6)
    )
    allowed_commands = math.ceil(window.elapsed_seconds / TICK_INTERVAL) + network_allowance
    allowed_tickbase_advance = (
        window.elapsed_server_ticks
        + TICKBASE_RATE_ALLOWANCE_TICKS
        + network_allowance
    )
    return window.commands > allowed_commands or window.tickbase_advance > allowed_tickbase_advance


@dataclass(frozen=True)
class MovementState:
    is_on_ground: bool = True
    is_ladder: bool = False
    is_noclip: bool = False
    is_incapacitated: bool = False
    is_charger_carried: bool = False
    is_jockey_ridden: bool = False
    touched_trigger_teleport_ticks_ago: int | None = None

    @property
    def is_excluded(self) -> bool:
        return (
            self.is_ladder
            or self.is_noclip
            or self.is_incapacitated
            or self.is_charger_carried
            or self.is_jockey_ridden
            or (
                self.touched_trigger_teleport_ticks_ago is not None
                and self.touched_trigger_teleport_ticks_ago <= 3
            )
        )


def is_teleport_jump(
    *,
    previous_position: tuple[float, float],
    current_position: tuple[float, float],
    elapsed_ticks: int,
    state: MovementState,
) -> bool:
    if state.is_excluded:
        return False

    distance = math.dist(previous_position, current_position)
    max_legal_distance = (
        TELEPORT_MAX_SPEED_UPS
        * TICK_INTERVAL
        * elapsed_ticks
        * TELEPORT_ALLOWANCE_MULTIPLIER
    )
    allowed_distance = max(max_legal_distance, TELEPORT_MIN_HORIZONTAL_UNITS)
    return distance > allowed_distance


def is_move_angle_inconsistent(
    *,
    served_yaw_degrees: float,
    forwardmove: float,
    sidemove: float,
    velocity: tuple[float, float],
    state: MovementState,
) -> bool:
    speed = math.hypot(*velocity)
    if state.is_excluded or not state.is_on_ground or speed < FAKE_ANGLE_MIN_SPEED_UPS:
        return False

    yaw_radians = math.radians(served_yaw_degrees)
    expected_x = (math.cos(yaw_radians) * forwardmove) + (-math.sin(yaw_radians) * sidemove)
    expected_y = (math.sin(yaw_radians) * forwardmove) + (math.cos(yaw_radians) * sidemove)
    expected_speed = math.hypot(expected_x, expected_y)
    if expected_speed <= 0.0:
        return False

    expected_yaw = math.degrees(math.atan2(expected_y, expected_x))
    velocity_yaw = math.degrees(math.atan2(velocity[1], velocity[0]))
    return normalize_angle_delta(velocity_yaw - expected_yaw) > FAKE_ANGLE_TOLERANCE_DEGREES


class MovementIntegrityTests(unittest.TestCase):
    def test_legit_constant_tickbase_offset_does_not_flag(self) -> None:
        model = TickbaseDeviationModel()

        flagged = [
            model.sample(server_tick=server_tick, latency_ticks=3, tickbase=server_tick - 3 + 12)
            for server_tick in range(1, 140)
        ]

        self.assertFalse(any(flagged))

    def test_tickbase_outrunning_elapsed_ticks_flags_lagexploit(self) -> None:
        model = TickbaseDeviationModel()
        for server_tick in range(1, 80):
            self.assertFalse(model.sample(server_tick=server_tick, latency_ticks=2, tickbase=server_tick - 2))

        flagged = [
            model.sample(server_tick=80 + index, latency_ticks=2, tickbase=80 + index - 2 + 16)
            for index in range(3)
        ]

        self.assertEqual(flagged, [False, False, True])

    def test_tick_regression_without_hurt_does_not_flag_backtrack_hit(self) -> None:
        model = BacktrackHitModel()

        self.assertFalse(model.command(game_tick=100, previous_tickcount=2000, tickcount=1988))

    def test_tick_regression_correlated_with_hurt_flags_backtrack_hit(self) -> None:
        model = BacktrackHitModel()
        model.command(game_tick=100, previous_tickcount=2000, tickcount=1988)

        self.assertTrue(model.hurt(game_tick=102))

    def test_forward_tick_jump_correlated_with_hurt_flags_backtrack_hit(self) -> None:
        model = BacktrackHitModel()
        model.command(game_tick=100, previous_tickcount=2000, tickcount=2016)

        self.assertTrue(model.hurt(game_tick=103))

    def test_normal_command_rate_and_tickbase_advance_do_not_flag_speedhack(self) -> None:
        self.assertFalse(
            is_speed_command_rate(
                SpeedWindow(
                    commands=30,
                    elapsed_seconds=1.0,
                    elapsed_server_ticks=30,
                    tickbase_advance=30,
                )
            )
        )

    def test_commands_faster_than_tickrate_flags_speed_command_rate(self) -> None:
        self.assertTrue(
            is_speed_command_rate(
                SpeedWindow(
                    commands=44,
                    elapsed_seconds=1.0,
                    elapsed_server_ticks=30,
                    tickbase_advance=30,
                )
            )
        )

    def test_tickbase_advancing_faster_than_server_time_flags_speed_command_rate(self) -> None:
        self.assertTrue(
            is_speed_command_rate(
                SpeedWindow(
                    commands=30,
                    elapsed_seconds=1.0,
                    elapsed_server_ticks=30,
                    tickbase_advance=42,
                )
            )
        )

    def test_normal_position_delta_does_not_flag_teleport_jump(self) -> None:
        self.assertFalse(
            is_teleport_jump(
                previous_position=(0.0, 0.0),
                current_position=(10.0, 0.0),
                elapsed_ticks=1,
                state=MovementState(),
            )
        )

    def test_impossible_position_jump_flags_teleport_jump(self) -> None:
        self.assertTrue(
            is_teleport_jump(
                previous_position=(0.0, 0.0),
                current_position=(900.0, 0.0),
                elapsed_ticks=1,
                state=MovementState(),
            )
        )

    def test_legitimate_teleport_exclusions_do_not_flag(self) -> None:
        excluded_states = [
            MovementState(touched_trigger_teleport_ticks_ago=1),
            MovementState(is_ladder=True),
            MovementState(is_noclip=True),
            MovementState(is_incapacitated=True),
            MovementState(is_charger_carried=True),
            MovementState(is_jockey_ridden=True),
        ]

        for state in excluded_states:
            with self.subTest(state=state):
                self.assertFalse(
                    is_teleport_jump(
                        previous_position=(0.0, 0.0),
                        current_position=(900.0, 0.0),
                        elapsed_ticks=1,
                        state=state,
                    )
                )

    def test_matching_served_move_and_velocity_direction_does_not_flag_fake_angle(self) -> None:
        self.assertFalse(
            is_move_angle_inconsistent(
                served_yaw_degrees=0.0,
                forwardmove=1.0,
                sidemove=0.0,
                velocity=(220.0, 0.0),
                state=MovementState(is_on_ground=True),
            )
        )

    def test_velocity_direction_inconsistent_with_served_move_flags_fake_angle(self) -> None:
        inconsistent_samples = [
            is_move_angle_inconsistent(
                served_yaw_degrees=90.0,
                forwardmove=1.0,
                sidemove=0.0,
                velocity=(220.0, 0.0),
                state=MovementState(is_on_ground=True),
            )
            for _ in range(FAKE_ANGLE_STREAK_TICKS)
        ]

        self.assertTrue(all(inconsistent_samples))

    def test_air_ladder_and_low_speed_do_not_flag_fake_angle(self) -> None:
        excluded_samples = [
            MovementState(is_on_ground=False),
            MovementState(is_on_ground=True, is_ladder=True),
            MovementState(is_on_ground=True, is_incapacitated=True),
        ]

        for state in excluded_samples:
            with self.subTest(state=state):
                self.assertFalse(
                    is_move_angle_inconsistent(
                        served_yaw_degrees=90.0,
                        forwardmove=1.0,
                        sidemove=0.0,
                        velocity=(220.0, 0.0),
                        state=state,
                    )
                )

        self.assertFalse(
            is_move_angle_inconsistent(
                served_yaw_degrees=90.0,
                forwardmove=1.0,
                sidemove=0.0,
                velocity=(80.0, 0.0),
                state=MovementState(is_on_ground=True),
            )
        )


if __name__ == "__main__":
    unittest.main()
