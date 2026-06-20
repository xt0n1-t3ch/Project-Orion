# Evidence Schema

Orion emits line-oriented evidence records to `addons/sourcemod/logs/orion.log`. Treat this file as the raw action ledger. Keep raw logs private; publish only redacted corpus exports.

## Raw evidence record

Each Orion line is a space-delimited `key=value` record. Quoted values are allowed. The stable fields are:

| Field | Required | Meaning |
|---|---:|---|
| `seq` | yes | Map-local evidence sequence. It is useful for ordering, not global identity. |
| `session` | yes | Runtime calibration session label from `orion_session_label` / `sm_orion_session`. |
| `type` | yes | Evidence family: `aim`, `angle_guard`, `movement`, `integrity`, `network`, `chat_guard`, `name_guard`, or `visibility_guard`. |
| `score` | yes | Rolling confidence score from `0.0` to `100.0+`. A single high score is review material, not ban proof by itself. |
| `action` | yes | Requested action at event time: `observe`, `alert`, or `ban`. In `shadow`, the effective action remains evidence-only. |
| `client` | yes | SourceMod client index at event time. Never use it as durable player identity. |
| `steamid` | yes | Steam2 auth ID when available. Redact it in shared corpus exports. |
| `name` | yes | Player name at event time. This is mutable and can contain hostile formatting. |
| `map` | yes | Current map. |
| `mode` | yes | Runtime mode: `shadow`, `alert`, or `enforce`. |
| `details` | yes | Quoted module-specific key/value context. |

Example:

```text
seq=12 session=reborn-aim-perfect-silent-20260620-r1 type=aim score=82.5 action=observe client=3 steamid=STEAM_1:1:123 name="player" map=c1m1_hotel mode=shadow details="reason=hurt_correlation target=5 angle_delta=42.0 mouse=0 target_ticks=1 tick=18902"
```

SourceMod may prefix the line with its own timestamp. Parsers must ignore non-Orion log lines and strip a SourceMod prefix before reading `seq=`.

## Details keys by evidence family

Use these keys when adding new SourcePawn evidence. The parser accepts unknown keys, but new keys should stay short, lower snake case, and unit-suffixed.

| Evidence family | Required details | Optional details |
|---|---|---|
| `aim` | `reason`, `target`, `tick` | `angle_delta`, `mouse`, `target_ticks`, `weapon`, `range`, `visible`, `shot_button`, `hitgroup` |
| `angle_guard` | `reason`, `tick` | `pitch`, `yaw`, `roll`, `delta`, `buttons` |
| `movement` | `reason`, `tick` | `jumps`, `ground_ticks`, `velocity`, `entropy`, `tick_drift`, `buttons` |
| `integrity` | `reason` | `cvar`, `value`, `expected`, `ping_ms`, `loss_percent`, `lerp_ms` |
| `network` | `reason` | `ping_ms`, `loss_percent`, `choke_percent`, `tick_drift` |
| `chat_guard` | `reason` | `message_length`, `control_chars`, `blocked` |
| `name_guard` | `reason` | `name_length`, `control_chars`, `blocked` |
| `visibility_guard` | `reason`, `entity` | `class`, `team`, `spawn_state`, `blocked` |

## Calibration session labels

Every lab run needs an operator label outside the raw log. Use this shape:

```text
<threat>-<feature>-<variant>-<yyyymmdd>-<run>
```

Examples:

- `reborn-aim-perfect-silent-20260620-r1`
- `reborn-visuals-ghost-glow-20260620-r1`
- `clean-high-skill-survivor-20260620-r2`
- `clean-high-ping-infected-20260620-r1`

Set the live label before each lab or clean run:

```text
sm_orion_session reborn-aim-perfect-silent-20260620-r1
sm_orion_status
```

The parser also accepts `--session-label` for older raw logs that do not yet contain `session=` or for export-time overrides.

## Corpus export schema

Tracked parser:

```powershell
python scripts/orion_evidence_report.py .\addons\sourcemod\logs\orion.log `
  --session-label reborn-aim-perfect-silent-20260620-r1 `
  --server-label BLACKWATCH `
  --redact-steamids `
  --json-out .\corpus\reborn-aim-perfect-silent-20260620-r1.json `
  --csv-out .\corpus\reborn-aim-perfect-silent-20260620-r1.csv
```

JSON root:

| Field | Meaning |
|---|---|
| `schema_version` | Always `orion-corpus-v1` for this parser version. |
| `session` | Session label, server label, record count, score filter, and redaction flag. |
| `counts` | Counts by evidence type, requested action, mode, and map. |
| `score_summary_by_type` | Count, max score, and average score by evidence type. |
| `players` | Per-player event count and max score. SteamIDs are pseudonymized when `--redact-steamids` is used. |
| `events` | Flat action ledger. Each item preserves the raw evidence fields plus parsed `details`. |

CSV output is intentionally flat for quick review in spreadsheets. The `details` column is JSON text.

## Review rules

- A ban-grade finding needs repeated evidence across time or two independent families, for example `aim` plus `angle_guard`, or `movement` plus `network`.
- `visibility_guard` proves data minimization activity. It does not prove a player used ESP by itself.
- `integrity` cvar failures are strong signals only after repeated failures or hostile values. Treat missing query responses as noisy until the corpus shows otherwise.
- `name` is hostile input. Do not paste raw names into public reports without escaping.
- Shared corpora must use `--redact-steamids`; private BLACKWATCH enforcement reviews may keep raw SteamIDs.
