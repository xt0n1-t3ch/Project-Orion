# Project Orion Threat Model

## Scope

Project Orion Phase 1 is a server-side SourceMod anti-cheat for competitive Left 4 Dead 2 servers. It does not inspect private client memory. It detects and mitigates cheat impact through server-observable behavior, visibility/data minimization, and structured evidence.

## Assets

- Competitive match integrity.
- Survivor/infected positional secrecy.
- Admin review quality.
- Ban reliability and false-positive safety.
- Server stability on hosted environments such as PingPerfect.

## Attacker capabilities

| Capability | Examples | Server-side reality | Orion response |
|---|---|---|---|
| DLL injection | Reborn-style `LoadLibraryA` / remote thread injection | not directly visible to a SourceMod server | behavior and evidence scoring only |
| ESP / wallhack / glow / chams | entity outlines, model glow, DME chams | rendered client-side after data is transmitted | suppress unnecessary entity transmission; score impossible awareness |
| Silent / perfect aim | shot lands without visible crosshair behavior | command/hit/tick correlation is observable | rolling aim evidence score |
| Humanized aim | smoothed low-FOV aim assist | single events are ambiguous | long-window statistical scoring with decay |
| Nospread / norecoil | improbable bullet outcomes | hit patterns are observable | weapon/range/movement probability scoring |
| Auto-bhop / macros | perfect jump timing | usercmd buttons, flags, and velocity are observable | movement automation scoring |
| Fakelag / backtrack / lerp abuse | tick/latency manipulation | interp values and tick anomalies are partially observable | cvar checks and tick-window scoring |
| Anti-OBS / Discord | hides overlay from captures | not server-relevant | rely on server telemetry, not screenshots |

## Controls

- `orion_visibility_guard`: blocks ghost infected and inactive infected transmission to survivors when safe.
- `orion_aim_analyzer`: scores attack windows, target acquisition, one-tick autoshoot streaks, invalid angles, hit/death correlation, and mouse-command inconsistencies.
- `orion_movement_analyzer`: scores perfect jump timing, velocity gain, command-number regressions, command tick drift, and tick anomalies.
- `orion_integrity`: queries interpolation and visual/prediction cvars, tracks ping/loss limits, blocks chat-clear abuse, and scores invalid player names.
- `orion_evidence`: logs structured evidence and gates alert/enforcement by mode.

## Lilac/SMAC replacement bar

Phase 1 covers Lilac's public feature classes: angle-cheat evidence, chat-clear patching, invalid cvar detection, bhop/macro evidence, aimbot/autoshoot/aimlock evidence, max interp evidence, max ping/loss evidence, backtrack/tick drift scoring, and invalid name detection. It also covers the SMAC classes relevant to L4D2 competitive servers: aimbot, wallhack/data minimization, cvars, speed/tick anomalies, spinhack-like invalid angles, and L4D2 ghost-state protection.

## False-positive stance

`orion_mode` defaults to `shadow`. Live bans are not a Phase 1 default. A threshold can move to alert/enforce only after a staging corpus proves normal competitive play, high-skill aim, high-skill movement, spectators, admins, and high-ping players remain below enforcement thresholds.
