# Evidence Schema

Orion emits line-oriented evidence records to `addons/sourcemod/logs/orion.log`.

## Fields

| Field | Meaning |
|---|---|
| `seq` | map-local evidence sequence |
| `type` | `aim`, `movement`, `integrity`, or `visibility_guard` |
| `score` | rolling confidence score from `0.0` to `100.0+` |
| `action` | `observe` or `ban` |
| `client` | SourceMod client index at event time |
| `steamid` | Steam2 auth ID when available |
| `name` | player name at event time |
| `map` | current map |
| `mode` | `shadow`, `alert`, or `enforce` |
| `details` | module-specific key/value context |

## Example

```text
seq=12 type=aim score=82.5 action=observe client=3 steamid=STEAM_1:1:123 name="player" map=c1m1_hotel mode=shadow details="reason=hurt_correlation target=5 angle_delta=42.0 mouse=0 target_ticks=1 tick=18902"
```
