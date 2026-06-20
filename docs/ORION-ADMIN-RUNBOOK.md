# Project Orion Admin Runbook

## Install

1. Compile `addons/sourcemod/scripting/orion.sp` with SourceMod 1.11 or newer.
2. Upload `orion.smx` to `addons/sourcemod/plugins/`.
3. Upload `cfg/sourcemod/orion.cfg`.
4. Restart the server or run `sm plugins load orion`.

## Safe first-run configuration

Keep the defaults for the first staging window:

```cfg
orion_enable "1"
orion_mode "shadow"
orion_visibility_guard_enable "1"
orion_visibility_pvs_enable "1"
orion_visibility_pvs_block_enable "0"
orion_admin_alerts "1"
```

## Validation commands

Run from RCON/server console:

```text
sm plugins list
find orion_
sm_orion_visibility_status
```

Expected:

- `Project Orion` is loaded.
- `orion_mode` reports `shadow`.
- `sm_orion_visibility_status` prints reason-coded allowed/suppressed counters.
- No `Unknown command` spam.
- No `Native` errors.

## Evidence review

Evidence is written to `addons/sourcemod/logs/orion.log`.

Set a session label before controlled lab or clean-corpus runs:

```text
sm_orion_session reborn_psilent_round1
sm_orion_status
```

Review for:

- repeated high scores against the same SteamID;
- correlation between aim/movement/integrity evidence;
- ping/loss context before action;
- demos or admin observations for high-impact bans.

Summarize a downloaded log into a calibration report:

```powershell
python scripts/orion_evidence_report.py .\orion.log --session-label reborn_psilent_round1 --json-out .\corpus.json --csv-out .\corpus.csv
python scripts/orion_evidence_report.py .\orion.log --session-label clean_scrim_round1 --min-score 50 --redact-steamids --json-out .\clean-corpus.json
```

Use separate session labels for clean and cheat-controlled runs, for example `clean_scrim_round1`, `reborn_glow_round1`, `reborn_psilent_round1`, and `reborn_bhop_round1`.

## Mode ladder

| Mode | Behavior | Use |
|---|---|---|
| `shadow` | logs only | default staging and threshold tuning |
| `alert` | logs and alerts admins | after zero false positives in shadow corpus |
| `enforce` | logs, alerts, and bans when action is `ban` | only after reviewed thresholds |

## BLACKWATCH integration rule

Do not re-enable old SMAC modules during Phase 1. Orion is the replacement candidate for Lilac/SMAC coverage on BLACKWATCH, but it still starts in `shadow` so the live corpus proves thresholds before `alert` or `enforce`.

## Lilac replacement parity

| Legacy coverage | Orion Phase 1 owner | Default posture |
|---|---|---|
| angle cheats and fake angles | `orion_aim_analyzer` + `orion_angle_guard_enable` | score and patch by evidence |
| chat clear and invalid chat control characters | `orion_integrity` + `orion_chat_guard_enable` | block message and log |
| invalid names/newlines | `orion_integrity` + `orion_name_guard_enable` | log evidence |
| invalid client convars | `orion_integrity` client cvar queries | score repeated bad values |
| max lerp/interp abuse | `orion_integrity` interpolation bounds | score, then enforce after corpus |
| max ping/loss abuse | `orion_integrity` network timer | disabled by default, configurable |
| basic aimbot/autoshoot/aimlock | `orion_aim_analyzer` | rolling evidence score |
| bhop/macro/strafe automation | `orion_movement_analyzer` | rolling evidence score |
| backtrack/fakelag tick abuse | `orion_movement_analyzer` + `orion_backtrack_patch_enable` | score suspicious drift |
| wallhack/ESP mitigation | `orion_visibility_guard` | suppress ghost/inactive infected; log SMAC-style PVS-hidden enemy evidence |

## Phase 3 visibility guard staging

The Phase 3 visibility guard is intentionally defensive and conservative. It currently:

- suppresses ghost or inactive infected player transmission to live survivors;
- keeps spectators and dead admin observers usable for review workflows;
- runs LOS/FOV trace checks for spawned enemy players and logs `reason=spawned_infected` PVS-hidden evidence;
- leaves spawned-enemy PVS blocking disabled by default through `orion_visibility_pvs_block_enable "0"`;
- fails open on trace-budget exhaustion instead of risking gameplay breakage;
- exposes reason-coded counters through `sm_orion_visibility_status`.

During staging, run one clean scrim and one controlled visual-cheat lab session with separate `sm_orion_session` labels, then capture:

```text
sm_orion_visibility_status
```

Review the counter mix before any broader transmit policy is enabled. `visibility_guard` evidence proves data minimization activity only; it is not ban proof by itself.

Only enable `orion_visibility_pvs_block_enable "1"` on staging after a clean scrim corpus shows no false positives for normal holds, ghost spawns, spectators, and admin review.
