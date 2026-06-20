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
orion_admin_alerts "1"
```

## Validation commands

Run from RCON/server console:

```text
sm plugins list
find orion_
```

Expected:

- `Project Orion` is loaded.
- `orion_mode` reports `shadow`.
- No `Unknown command` spam.
- No `Native` errors.

## Evidence review

Evidence is written to `addons/sourcemod/logs/orion.log`.

Review for:

- repeated high scores against the same SteamID;
- correlation between aim/movement/integrity evidence;
- ping/loss context before action;
- demos or admin observations for high-impact bans.

## Mode ladder

| Mode | Behavior | Use |
|---|---|---|
| `shadow` | logs only | default staging and threshold tuning |
| `alert` | logs and alerts admins | after zero false positives in shadow corpus |
| `enforce` | logs, alerts, and bans when action is `ban` | only after reviewed thresholds |

## BLACKWATCH integration rule

Do not re-enable old SMAC modules during Phase 1. Run Orion beside Lilac until Orion has its own staging evidence corpus.
