# Project Orion test suite

Run the whole suite:

```powershell
python -m unittest discover -s tests -p "test_*.py"
```

The SourcePawn detection logic cannot be executed off the game server, so each
detection test is a faithful Python mirror of that detection's decision gate. A
mirror can drift from the live `.sp`; the live RCON shadow/alert run on the
BLACKWATCH server is the ground-truth proof, and these tests are the fast
regression guard that the gate's intended behavior is preserved.

## Suites by coverage

| Suite | Covers (cheat feature -> detection) | What it asserts |
|---|---|---|
| `test_orion_fp_replay.py` | the false-positive fix: tickbase baseline (lagexploit FP), aim `angle_history` hit-gate | a stable constant tick offset (e.g. owner -23) and absurd state-artifact drift never ban; a sudden tickbase jump and oscillating drift away from baseline still ban; `target=-1` angle turns never ban |
| `test_aim_integrity.py` | aimbot/silent/perfect-silent (`silent_angle_mismatch`), nospread/fake-upgrade (`fake_upgrade_nospread`), norecoil (`norecoil_flat`), rapidfire/autoshoot (`rapidfire_cadence`) | clean aim does not flag; off-crosshair hits, laser-tight-without-upgrade, flat burst recoil, and sub-cycle fire do flag |
| `test_movement_integrity.py` | lagexploit/fakelag/fakeping, backtrack/forwardtrack (`backtrack_hit`), speedhack (`speed_command_rate`), teleport (`teleport_jump`), fake-angle (`move_angle_inconsistency`); bhop/strafe/speed via `orion_movement_analyzer` jump/speed windows | constant offset + normal speed + matching velocity + normal positions do not flag; tickbase outrunning elapsed, tick regression with a hit, commands faster than tickrate, impossible position jumps, and velocity inconsistent with the served move under a fake yaw do flag |
| `test_ability_guard.py` | special-infected ability glitches: infinite spit, double vomit, infinite tank punch, infinite stumble, charger rotation, jockey re-entry, air stuck | within-cooldown re-use and impossible state transitions flag; legal spacing and single uses do not |
| `test_visibility_guard.py` | visual cheats (chams/ESP/wallhack/radar) -- mitigation + behavioral only: data-minimization + `prefire_through_wall` | an enemy with line of sight / recently visible is not flagged; sustained precise aim+fire at a PVS-hidden, not-recently-visible enemy is flagged; trace-budget caps fail open |
| `test_reborn_analysis.py` | static dissection of the Reborn trainer sample (file inventory, feature strings) | the documented capability matrix matches the analyzed sample |
| `test_orion_evidence_report.py` | the `scripts/orion_evidence_report.py` corpus tooling | parsing, grouping, redaction, and report output for calibration sessions |
| `test_docs_coverage.py` | docs freshness | the required threat-model, runbook, research, and evidence-schema docs exist and are non-trivial |

## Honest coverage notes

- **Detectable behaviorally (tested + live-provable):** aimbot/silent/perfect-silent, fake-angle, nospread (statistical + fake-upgrade), norecoil, rapidfire/autoshoot, bhop/strafe/speed, lagexploit/fakelag/fakeping, backtrack/forwardtrack, teleport, special-infected ability glitches.
- **Mitigation only (NOT directly detectable server-side):** chams, ESP, wallhack, radar, glow, boxes, tracers -- the server can only starve data (PVS/ghost transmit suppression) and catch the behavior they enable (`prefire_through_wall`). The tests assert the mitigation/behavioral path, not detection of the render hack itself.
- **Out of scope:** anti-OBS/anti-Discord, the loader/auth, HWID -- client-only, no server signal.
