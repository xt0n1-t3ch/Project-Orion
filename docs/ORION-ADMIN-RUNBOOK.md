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
sm_orion_status
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

## First live shadow session

Use this runbook for Tony's first live BLACKWATCH play session with Orion loaded but non-enforcing. The goal is to collect a clean, reviewable corpus without changing match outcomes.

### 1. Pre-session RCON setup

Use the server console directly or prefix each line with `rcon` from a connected client. Keep the session label in lower snake case or lower kebab case so parser outputs sort cleanly.

```text
rcon sm plugins list
rcon find orion_
rcon sm_cvar orion_enable 1
rcon sm_cvar orion_mode shadow
rcon sm_cvar orion_admin_alerts 1
rcon sm_cvar orion_visibility_guard_enable 1
rcon sm_cvar orion_visibility_pvs_enable 1
rcon sm_cvar orion_visibility_pvs_block_enable 0
rcon sm_cvar orion_evidence_log_level 2
rcon sm_orion_session live_shadow_blackwatch_20260620_r1
rcon sm_orion_status
rcon sm_orion_readiness
rcon sm_orion_visibility_status
```

Expected RCON proof before players join:

- `sm plugins list` shows `Project Orion`.
- Optional: run `sm plugins info <id>` with the plugin id from `sm plugins list` if you need the loaded filename/version.
- `sm_orion_status` prints `[Orion] enabled=1 mode=shadow session=live_shadow_blackwatch_20260620_r1`.
- `sm_orion_readiness` prints `readiness=shadow_ready`, the current thresholds, guard toggles, network bounds, and cvar-policy scan width.
- `sm_orion_visibility_status` prints reason-coded `allowed` and `suppressed` counters.
- `orion_visibility_pvs_block_enable` remains `0`; spawned-enemy PVS blocking is not part of the first live session.

If Orion is missing, noisy, or not in `shadow`, stop the session and unload it:

```text
rcon sm plugins unload orion
rcon sm plugins list
```

### 2. Session labels to use

Create one label per corpus slice. Do not reuse labels across clean live play and controlled lab runs.

| Slice | Label example | Purpose |
|---|---|---|
| First live shadow play | `live_shadow_blackwatch_20260620_r1` | Real match telemetry with no enforcement |
| Clean scrim baseline | `clean_scrim_blackwatch_20260620_r1` | Known-clean false-positive corpus |
| High-ping clean player | `clean_high_ping_blackwatch_20260620_r1` | Latency and loss false-positive check |
| Reborn pSilent lab | `lab_reborn_psilent_20260620_r1` | Aim/angle controlled positive corpus |
| Reborn visuals lab | `lab_reborn_visuals_20260620_r1` | Visibility/PVS evidence review |
| Reborn bhop lab | `lab_reborn_bhop_20260620_r1` | Movement/autotrigger controlled positive corpus |

Switch labels only at round boundaries:

```text
rcon sm_orion_session clean_scrim_blackwatch_20260620_r1
rcon sm_orion_status
```

### 3. Live operator checklist

During the match, capture the status at start, halftime/map change, and end:

```text
rcon sm_orion_status
rcon sm_orion_visibility_status
rcon status
```

Record the following in the admin notes next to the session label:

- map, start time, end time, and number of human players;
- known admins, spectators, and demo reviewers;
- players with unusual ping/loss, packet choke, or reconnect loops;
- any admin-observed suspicious moments with tick/time if a demo is available;
- whether any old SMAC/Lilac modules were loaded during the session.

Do not ban from Orion evidence during this first live session. In `shadow`, every `action=ban` line is a threshold recommendation only.

### 4. Retrieve and parse evidence

After the session, copy the raw log to a private local corpus folder. Keep raw logs private because they contain SteamIDs and names.

```powershell
New-Item -ItemType Directory -Force .\corpus\raw, .\corpus\reports | Out-Null
scp blackwatch:/left4dead2/addons/sourcemod/logs/orion.log .\corpus\raw\orion-live-shadow-blackwatch-20260620-r1.log
```

If SCP is not available, download `addons/sourcemod/logs/orion.log` through the host panel or FTP/SFTP and save it under `.\corpus\raw\`.

Build the private review report and a redacted shareable corpus:

```powershell
python scripts/orion_evidence_report.py .\corpus\raw\orion-live-shadow-blackwatch-20260620-r1.log `
  --session-label live_shadow_blackwatch_20260620_r1 `
  --server-label BLACKWATCH `
  --json-out .\corpus\reports\live-shadow-blackwatch-20260620-r1.private.json `
  --csv-out .\corpus\reports\live-shadow-blackwatch-20260620-r1.private.csv

python scripts/orion_evidence_report.py .\corpus\raw\orion-live-shadow-blackwatch-20260620-r1.log `
  --session-label live_shadow_blackwatch_20260620_r1 `
  --server-label BLACKWATCH `
  --redact-steamids `
  --json-out .\corpus\reports\live-shadow-blackwatch-20260620-r1.redacted.json `
  --csv-out .\corpus\reports\live-shadow-blackwatch-20260620-r1.redacted.csv
```

Triage the report in this order:

1. `counts.mode` must be only `shadow`.
2. `counts.action` may include `observe`, `alert`, or `ban`, but `mode=shadow` means no live action was applied.
3. Sort the CSV by `score` descending and group by `steamid`, `type`, and `details.reason`.
4. Treat repeated evidence across two families as stronger than a single high score.
5. Review `visibility_guard` as data-minimization telemetry only, not ban proof.

### 5. Shadow to alert to enforce gate

Do not advance modes on the same night as the first live shadow session. Use this gate after the corpus is reviewed.

| Gate | Minimum evidence | Allowed command | Rollback |
|---|---|---|---|
| Stay in `shadow` | Any unexplained clean-player high score, parser error, unknown module noise, or missing admin notes | `rcon sm_cvar orion_mode shadow` | Already safest |
| Promote to `alert` | At least one clean live/scrim corpus with no ban-grade false positives, parser output reviewed, and admin alerts are useful but non-spammy | `rcon sm_cvar orion_mode alert` then `rcon sm_orion_status` | `rcon sm_cvar orion_mode shadow` |
| Promote to `enforce` | Repeated cheat-controlled positives, zero unresolved clean false positives, thresholds reviewed, ban provider verified, and Tony explicitly approves enforcement | `rcon sm_cvar orion_mode enforce` then `rcon sm_orion_status` | `rcon sm_cvar orion_mode alert` or `rcon sm_cvar orion_mode shadow` |

Before `enforce`, verify the ban path is intentional:

```text
rcon sm_cvar orion_ban_provider
rcon sm_cvar orion_ban_minutes
rcon sm_cvar orion_mode enforce
rcon sm_orion_status
```

If `orion_ban_provider` is `none`, enforcement should not be considered live ban coverage. If it is `basebans` or `sourcebans`, run a sacrificial staging test before touching production enforcement.

### 6. False-positive corpus checklist

A clean corpus is required before `alert`, and a broader clean corpus is required before `enforce`.

- Normal survivor holds with infected behind walls and doors.
- Ghost infected pathing, spawning, despawning, and spectator/admin observing.
- High-skill flicks, shotgun clears, common-infected spray transfers, and tank rocks.
- Bhop-like legitimate movement, ladder/ledge interactions, stumble, charger/smoker pulls, and common infected body-blocks.
- High ping, packet loss, choke, reconnect, late join, map transition, and pause/unpause conditions.
- Name changes, Unicode names, long names, chat binds, and harmless control-looking chat copied from configs.
- Client cvar query noise from vanilla clients, Linux clients, and players with unusual but legal rates/interp.
- Demo/admin observation attached for every clean-player event with `score >= 75` or any `action=ban`.

Promotion is blocked until each false-positive item is either covered by a clean session label or explicitly deferred with owner, reason, and next test date.

## Mode ladder

| Mode | Behavior | Use |
|---|---|---|
| `shadow` | logs evidence, applies narrow defensive blocks for hostile chat/command abuse, and suppresses ghost/inactive infected transmit | default staging and threshold tuning |
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
| usercmd/eye-test tamper | `orion_usercmd_guard` | shadow evidence for reuse, regression, tick/button mutation |
| command/name/client abuse | `orion_abuse_guard` | block obvious control abuse; observe rate/noisy commands |
| basic aimbot/autoshoot/aimlock | `orion_aim_analyzer` | rolling evidence score plus angle history |
| bhop/macro/strafe automation | `orion_movement_analyzer` | rolling evidence score plus token bucket |
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

## Phase 4 parity staging

Phase 4 adds the next LILAC/SMAC parity controls in shadow-first posture:

- `usercmd_guard`: command-number reuse/regression, tickcount mutation, button mutation, and impossible pitch/roll evidence with L4D2 state exceptions.
- `abuse_command` / `abuse_name`: command-rate, dangerous command, chat/name control abuse, and name-change spam evidence.
- `integrity`: 38-entry cvar policy registry based on Orion, LILAC, SMAC, and BLACKWATCH client-cvar patterns.
- `movement`: speedhack token bucket, command-gap/choke/fakelag, jump-release/autotrigger, and latency-aware backtrack windows.
- `aim`: angle history ring, snap2/total-delta/repeated-angle patterns, autoshoot support, and starter weapon-outcome/nospread details.

Treat these as corpus-building controls until clean and cheat-controlled sessions are both reviewed.
