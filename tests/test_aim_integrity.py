import unittest
from dataclasses import dataclass


AIM_SCORE_THRESHOLD = 75.0
INTEGRITY_SCORE_THRESHOLD = 70.0
SILENT_MISMATCH_DEGREES = 16.0
SILENT_MIN_HITS = 3
RAPIDFIRE_MIN_CYCLE_TICKS = 2
RAPIDFIRE_MIN_SIGNALS = 3
NORECOIL_MIN_BURST_SHOTS = 8
NORECOIL_FLAT_PITCH_DEGREES = 0.75
NORECOIL_MIN_HITS = 3
LASER_TIGHT_DEGREES = 3.0
LASER_TIGHT_MIN_HITS = 3
LASER_SIGHT_BIT = 1 << 2


@dataclass
class AimIntegrityMirror:
    aim_score: float = 0.0
    integrity_score: float = 0.0
    silent_hits: int = 0
    rapidfire_cadence_streak: int = 0
    rapidfire_next_attack_streak: int = 0
    rapidfire_hit_streak: int = 0
    attack_toggle_streak: int = 0
    norecoil_hit_streak: int = 0
    laser_tight_hit_streak: int = 0
    fake_upgrade_streak: int = 0
    last_fire_tick: int = 0
    last_tick: int = 0
    burst_fire_ticks: int = 0
    burst_min_pitch: float = 0.0
    burst_max_pitch: float = 0.0
    burst_pitch_motion: float = 0.0

    def record_fire(self, tick: int, legal_cycle_ticks: int = RAPIDFIRE_MIN_CYCLE_TICKS, next_attack_ready: bool = False) -> None:
        if self.last_fire_tick and tick - self.last_fire_tick <= 2:
            self.burst_fire_ticks += 1
        else:
            self.burst_fire_ticks = 1
            self.norecoil_hit_streak = 0
            self.burst_min_pitch = 0.0
            self.burst_max_pitch = 0.0
            self.burst_pitch_motion = 0.0

        interval = tick - self.last_fire_tick if self.last_fire_tick else -1
        if 0 < interval < legal_cycle_ticks:
            self.rapidfire_cadence_streak += 1
        elif self.rapidfire_cadence_streak:
            self.rapidfire_cadence_streak -= 1

        if next_attack_ready:
            self.rapidfire_next_attack_streak += 1
        elif self.rapidfire_next_attack_streak:
            self.rapidfire_next_attack_streak -= 1

        self.last_fire_tick = tick
        self.last_tick = tick

    def record_burst_pitch(self, pitch: float, pitch_delta: float) -> None:
        if self.burst_fire_ticks <= 1:
            self.burst_min_pitch = pitch
            self.burst_max_pitch = pitch
            self.burst_pitch_motion = 0.0
            return

        self.burst_min_pitch = min(self.burst_min_pitch, pitch)
        self.burst_max_pitch = max(self.burst_max_pitch, pitch)
        self.burst_pitch_motion += abs(pitch_delta)

    def silent_angle_mismatch_hit(self, served_yaw_degrees: float, victim_yaw_degrees: float) -> bool:
        mismatch = abs(normalize_angle(served_yaw_degrees - victim_yaw_degrees))
        if mismatch < SILENT_MISMATCH_DEGREES:
            self.silent_hits = max(0, self.silent_hits - 1)
            return False

        self.silent_hits += 1
        self.aim_score += 12.0 if self.silent_hits < SILENT_MIN_HITS else 22.0
        return self.silent_hits >= SILENT_MIN_HITS and self.aim_score >= AIM_SCORE_THRESHOLD

    def rapidfire_hit(self) -> bool:
        has_signal = (
            self.rapidfire_cadence_streak >= RAPIDFIRE_MIN_SIGNALS
            or self.rapidfire_next_attack_streak >= RAPIDFIRE_MIN_SIGNALS
            or self.attack_toggle_streak >= RAPIDFIRE_MIN_SIGNALS + 1
        )
        if not has_signal:
            self.rapidfire_hit_streak = max(0, self.rapidfire_hit_streak - 1)
            return False

        self.rapidfire_hit_streak += 1
        self.aim_score += 10.0 if self.rapidfire_hit_streak < 2 else 20.0
        return self.rapidfire_hit_streak >= 2 and self.aim_score >= AIM_SCORE_THRESHOLD

    def norecoil_hit(self) -> bool:
        pitch_span = self.burst_max_pitch - self.burst_min_pitch
        has_flat_burst = (
            self.burst_fire_ticks >= NORECOIL_MIN_BURST_SHOTS
            and pitch_span <= NORECOIL_FLAT_PITCH_DEGREES
            and self.burst_pitch_motion <= NORECOIL_FLAT_PITCH_DEGREES * 2.0
        )
        if not has_flat_burst:
            self.norecoil_hit_streak = max(0, self.norecoil_hit_streak - 1)
            return False

        self.norecoil_hit_streak += 1
        self.aim_score += 10.0 if self.norecoil_hit_streak < NORECOIL_MIN_HITS else 20.0
        return self.norecoil_hit_streak >= NORECOIL_MIN_HITS and self.aim_score >= AIM_SCORE_THRESHOLD

    def record_laser_tight_hit(self, served_yaw_degrees: float, victim_yaw_degrees: float, hit_group: int, aim_delta_degrees: float) -> None:
        mismatch = abs(normalize_angle(served_yaw_degrees - victim_yaw_degrees))
        if hit_group in (1, 2) and mismatch <= LASER_TIGHT_DEGREES and aim_delta_degrees <= LASER_TIGHT_DEGREES:
            self.laser_tight_hit_streak += 1
        elif self.laser_tight_hit_streak:
            self.laser_tight_hit_streak -= 1

    def fake_upgrade_nospread_hit(self, upgrade_bits: int, upgraded_primary_ammo_loaded: int) -> bool:
        del upgraded_primary_ammo_loaded
        has_tight_hits = self.laser_tight_hit_streak >= LASER_TIGHT_MIN_HITS
        has_laser_upgrade = (upgrade_bits & LASER_SIGHT_BIT) != 0
        if not has_tight_hits or has_laser_upgrade:
            self.fake_upgrade_streak = 0 if has_laser_upgrade else max(0, self.fake_upgrade_streak - 1)
            return False

        self.fake_upgrade_streak += 1
        self.integrity_score += 12.0 if self.fake_upgrade_streak < 2 else 24.0
        return self.fake_upgrade_streak >= 2 and self.integrity_score >= INTEGRITY_SCORE_THRESHOLD


def normalize_angle(angle_degrees: float) -> float:
    while angle_degrees > 180.0:
        angle_degrees -= 360.0
    while angle_degrees < -180.0:
        angle_degrees += 360.0
    return angle_degrees


class AimIntegrityGateTests(unittest.TestCase):
    def test_clean_shot_does_not_flag_any_aim_integrity_gate(self) -> None:
        mirror = AimIntegrityMirror()

        for tick in range(10, 15):
            mirror.record_fire(tick * RAPIDFIRE_MIN_CYCLE_TICKS, legal_cycle_ticks=RAPIDFIRE_MIN_CYCLE_TICKS)
            mirror.record_burst_pitch(pitch=float(tick), pitch_delta=1.0)
            mirror.record_laser_tight_hit(served_yaw_degrees=0.0, victim_yaw_degrees=0.0, hit_group=3, aim_delta_degrees=4.0)

            self.assertFalse(mirror.silent_angle_mismatch_hit(served_yaw_degrees=0.0, victim_yaw_degrees=0.0))
            self.assertFalse(mirror.rapidfire_hit())
            self.assertFalse(mirror.norecoil_hit())
            self.assertFalse(mirror.fake_upgrade_nospread_hit(upgrade_bits=LASER_SIGHT_BIT, upgraded_primary_ammo_loaded=0))

    def test_silent_angle_mismatch_flags_repeated_hits_off_served_crosshair(self) -> None:
        mirror = AimIntegrityMirror()

        flagged = False
        for _ in range(5):
            flagged = mirror.silent_angle_mismatch_hit(served_yaw_degrees=45.0, victim_yaw_degrees=0.0)

        self.assertTrue(flagged)

    def test_fake_upgrade_nospread_flags_laser_tight_hits_without_laser_bit(self) -> None:
        mirror = AimIntegrityMirror()

        flagged = False
        for _ in range(6):
            mirror.record_laser_tight_hit(served_yaw_degrees=0.0, victim_yaw_degrees=0.0, hit_group=1, aim_delta_degrees=0.4)
            flagged = mirror.fake_upgrade_nospread_hit(upgrade_bits=0, upgraded_primary_ammo_loaded=0)

        self.assertTrue(flagged)

    def test_norecoil_flat_flags_sustained_flat_recoil_with_hits(self) -> None:
        mirror = AimIntegrityMirror()
        mirror.burst_fire_ticks = NORECOIL_MIN_BURST_SHOTS
        mirror.burst_min_pitch = -0.2
        mirror.burst_max_pitch = 0.2
        mirror.burst_pitch_motion = 0.6

        flagged = False
        for _ in range(5):
            flagged = mirror.norecoil_hit()

        self.assertTrue(flagged)

    def test_rapidfire_cadence_flags_sub_cycle_hit_cadence(self) -> None:
        mirror = AimIntegrityMirror()

        flagged = False
        for tick in range(1, 8):
            mirror.record_fire(tick, legal_cycle_ticks=3, next_attack_ready=True)
            flagged = mirror.rapidfire_hit()

        self.assertTrue(flagged)


if __name__ == "__main__":
    unittest.main()
