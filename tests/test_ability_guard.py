import unittest
from dataclasses import dataclass


@dataclass(frozen=True)
class AbilityEvidence:
    reason: str
    ability: str
    tick: int


class AbilityGuardMirror:
    DOUBLE_VOMIT_WINDOW_TICKS = 1

    def __init__(self, cooldown_ticks: dict[str, int]) -> None:
        self.cooldown_ticks = cooldown_ticks
        self.last_use_tick: dict[str, int] = {}
        self.last_report_tick: dict[tuple[str, str], int] = {}

    def record_use(self, ability: str, tick: int) -> list[AbilityEvidence]:
        evidence: list[AbilityEvidence] = []
        last_tick = self.last_use_tick.get(ability)

        if ability == "vomit" and last_tick is not None and 0 <= tick - last_tick <= self.DOUBLE_VOMIT_WINDOW_TICKS:
            self._append_once_per_tick(evidence, "ability_state_impossible", ability, tick)

        cooldown = self.cooldown_ticks[ability]
        if last_tick is not None and 0 < tick - last_tick < cooldown:
            self._append_once_per_tick(evidence, "ability_cooldown_abuse", ability, tick)

        self.last_use_tick[ability] = tick
        return evidence

    def _append_once_per_tick(self, evidence: list[AbilityEvidence], reason: str, ability: str, tick: int) -> None:
        report_key = (ability, reason)
        if self.last_report_tick.get(report_key) == tick:
            return

        self.last_report_tick[report_key] = tick
        evidence.append(AbilityEvidence(reason=reason, ability=ability, tick=tick))


class AbilityGuardMirrorTests(unittest.TestCase):
    def test_reuse_inside_cooldown_flags_cooldown_abuse(self) -> None:
        guard = AbilityGuardMirror({"spit": 10})

        self.assertEqual(guard.record_use("spit", 100), [])
        evidence = guard.record_use("spit", 105)

        self.assertEqual(evidence, [AbilityEvidence(reason="ability_cooldown_abuse", ability="spit", tick=105)])

    def test_reuse_after_legal_spacing_does_not_flag(self) -> None:
        guard = AbilityGuardMirror({"spit": 10})

        self.assertEqual(guard.record_use("spit", 100), [])
        self.assertEqual(guard.record_use("spit", 110), [])

    def test_double_vomit_inside_state_window_flags_impossible_state(self) -> None:
        guard = AbilityGuardMirror({"vomit": 30})

        self.assertEqual(guard.record_use("vomit", 200), [])
        evidence = guard.record_use("vomit", 201)

        self.assertIn(AbilityEvidence(reason="ability_state_impossible", ability="vomit", tick=201), evidence)

    def test_single_vomit_does_not_flag_impossible_state(self) -> None:
        guard = AbilityGuardMirror({"vomit": 30})

        evidence = guard.record_use("vomit", 200)

        self.assertEqual(evidence, [])

    def test_duplicate_same_tick_reuse_does_not_double_fire_cooldown_evidence(self) -> None:
        guard = AbilityGuardMirror({"vomit": 30})

        self.assertEqual(guard.record_use("vomit", 200), [])
        first_duplicate = guard.record_use("vomit", 200)
        second_duplicate = guard.record_use("vomit", 200)

        self.assertEqual(first_duplicate, [AbilityEvidence(reason="ability_state_impossible", ability="vomit", tick=200)])
        self.assertEqual(second_duplicate, [])


if __name__ == "__main__":
    unittest.main()
