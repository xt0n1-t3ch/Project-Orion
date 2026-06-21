# SMAC and Lilac Parity Audit

SMAC is fully disabled on the server and can be retired after Orion covers the useful detection surface. Lilac remains the incumbent reference for parity.

## SMAC parity

| SMAC module | Useful detection surface | Orion equivalent | Parity status |
|---|---|---|---|
| `smac_aimbot` | Snap aim, repeated target acquisition, and impossible aim corrections | `orion_aim_analyzer` | Improves it by requiring fresh valid target context, hit/death correlation, rolling scores, and `target > 0` for angle-history bans |
| `smac_autotrigger` | Firing exactly when a target crosses the crosshair | `orion_aim_analyzer` plus future weapon timing guard | Partially matches; Orion already records target and fire context, but weapon-specific trigger timing should remain observe-first until calibrated |
| `smac_eyetest` | Invalid angles, impossible view state, and client angle sanity | `orion_aim_analyzer` | Matches for invalid angle classes and improves raw-turn handling by refusing to ban `target=-1` rows |
| `smac_speedhack` | Tickrate, movement, and speed anomalies | `orion_movement_analyzer` | Improves it through active-sample gating, tick-drift sanity clamp, per-client baseline, and sustained-deviation streaks |
| `smac_spinhack` | Extreme repeated yaw changes | `orion_aim_analyzer` | Matches only when paired with invalid angle or valid-target evidence; raw turn magnitude alone is intentionally not ban-grade |
| `smac_wallhack` | Server-side visibility restriction and awareness evidence | `orion_visibility_guard` plus aim evidence | Improves it by using narrow ghost-infected suppression and evidence review instead of broad data blocking |
| `smac_cvars` | Forbidden or invalid client convars | Integrity guard | Matches useful policy checks when convar evidence is available; Orion should keep bans tied to exact forbidden values |
| `smac_commands` | Blocked commands and command abuse | Integrity guard | Matches useful command abuse checks with structured evidence rows |

## Lilac parity

| Lilac check | Useful detection surface | Orion equivalent | Parity status |
|---|---|---|---|
| Angle cheats | Invalid pitch/roll, impossible angle transitions, and spin-like behavior | `orion_aim_analyzer` | Improves it by separating invalid-angle bans from raw turn magnitude and by requiring valid target context for angle-history bans |
| Invalid convars | Bad client settings or blocked values | Integrity guard | Matches when convar evidence is present |
| Bhop | Jump timing and airborne `IN_JUMP` behavior | `orion_movement_analyzer` | Matches with rolling movement evidence; remains observe-first for high-skill edge cases |
| Backtrack | Hit registration outside acceptable chronology or interpolation | Integrity and movement analyzers | Partially matches; needs max-interp and hit-window evidence before auto-ban |
| Aimlock | Repeated lock-on or snap-to-target patterns | `orion_aim_analyzer` | Improves it through fresh target gating, target identity, mouse context, and hit/death correlation |
| Max interp | Excessive interpolation settings | Integrity guard | Matches as a policy check; should fail closed only on exact values above the configured ceiling |
| Max ping | Ping policy enforcement | Admin policy guard | Matches as server policy, not cheat proof |
| Invalid names | Bad names, control characters, or impersonation patterns | Integrity guard | Matches with low FP risk when checks are exact |
| Chat-clear | Chat payloads that clear or disrupt client chat | Integrity guard | Matches with exact payload detection and structured evidence |

## Retirement readout

- SMAC is safe to retire because it is already disabled and Orion now covers the useful server-observable behavior through dedicated analyzers.
- Lilac should remain the incumbent comparator until Orion's live corpus stays clean under enforcement gates for movement, aim, and integrity evidence.
- Orion improves the highest-risk FP areas by refusing absolute tick-drift bans, skipping idle/synthetic frames, sanity-killing state artifacts, learning per-client drift baselines, and refusing angle-history bans when `target=-1`.
