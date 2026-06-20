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

- `orion_visibility_guard`: blocks ghost infected and inactive infected transmission to survivors when safe, exempts spectator/admin observation paths, and records reason-coded allowed/suppressed transmit counters for Phase 3 calibration.
- `orion_usercmd_guard`: scores SMAC-style usercmd reuse, command-number regression, tickcount mutation, button mutation, and impossible pitch/roll evidence with L4D2 view-state exceptions.
- `orion_aim_analyzer`: scores attack windows, target acquisition, one-tick autoshoot streaks, invalid angles, hit/death correlation, mouse-command inconsistencies, angle-history snaps, repeated deltas, and starter weapon-outcome signals.
- `orion_movement_analyzer`: scores perfect jump timing, jump-release/autotrigger cadence, velocity gain, speedhack token-bucket exhaustion, command gaps, fakelag/choke context, command-number regressions, and latency-aware tick drift.
- `orion_cvar_policy`: owns the data-driven client-cvar policy registry for Orion/LILAC/SMAC/BLACKWATCH visual and prediction cvars.
- `orion_integrity`: queries cvar policies, tracks ping/loss limits, blocks chat-clear abuse, and scores invalid player names.
- `orion_abuse_guard`: scores command-rate abuse, dangerous client-command attempts, and name-change churn.
- `orion_evidence`: logs structured evidence and gates alert/enforcement by mode.

## Phase 3 visibility/PVS guard

The Phase 3 guard keeps runtime enforcement conservative while adding SMAC-style PVS evidence:

- `SDKHook_SetTransmit` remains the player-transmit interception point.
- `sm_orion_visibility_status` reports reason-coded allowed and suppressed counters after a staging run.
- Spectators are allowed through so casters/admin observers do not lose legitimate observer data.
- Dead admin observers with `orion_visibility_bypass` are allowed through for review workflows.
- Alive survivors are not granted an admin bypass, so a playing admin does not receive hidden infected data.
- Ghost/inactive infected transmission remains blocked immediately.
- Spawned enemy players are checked with FOV plus center/weapon-tip/hull-corner LOS traces and emit `reason=pvs_hidden_enemy` evidence after the configured grace window.
- Spawned-enemy PVS blocking is disabled by default with `orion_visibility_pvs_block_enable "0"` until the clean corpus proves it safe.

The remaining full PVS parity work needs these SourceMod/L4D2 pieces validated before enabling broader blocking:

| Need | SourceMod hook/forward | Compile/runtime blocker |
|---|---|---|
| Player transmit policy | `SDKHook_SetTransmit` on each client | already wired; duplicate hooks are guarded by `g_OrionVisibilityHooked` |
| Map reset | `OnMapStart` | wired to reset counters |
| Observer/admin exceptions | `GetClientTeam`, `IsPlayerAlive`, `CheckCommandAccess` | policy is conservative; admin bypass is dead-observer only |
| LOS/FOV cache | `GetClientEyePosition`, `GetClientEyeAngles`, `TR_TraceRayFilter` | compiled; still needs live L4D2 collision validation before block mode |
| Entity transmit rules | `OnEntityCreated`, `SDKHook_Spawn`, `SDKHook_SetTransmit` for projectiles/weapons | needs class allowlist for L4D2 weapons, hittables, throwables, and infected abilities |
| Per-target PVS cache | short timer or tick-window cache keyed by observer/entity | needs CPU budget proof under full 8v8/spectator load |
| Evidence export | `Orion_Evidence_Submit` with `visibility_guard` details | reason-coded suppression is wired; allowed counters stay status-only to avoid log spam |

## Lilac/SMAC replacement bar

Phase 1 covers Lilac's public feature classes: angle-cheat evidence, chat-clear patching, invalid cvar detection, bhop/macro evidence, aimbot/autoshoot/aimlock evidence, max interp evidence, max ping/loss evidence, backtrack/tick drift scoring, and invalid name detection. It also covers the SMAC classes relevant to L4D2 competitive servers: aimbot, wallhack/data minimization, cvars, speed/tick anomalies, spinhack-like invalid angles, and L4D2 ghost-state protection.

## Remaining hardening backlog

The replacement path is not complete until these slices are proven against BLACKWATCH corpora:

- Full PVS block mode: enable spawned-enemy transmit blocking only after clean corpus validation.
- Weapon/entity transmit parity: class allowlist for weapons, hittables, throwables, projectiles, and infected ability entities.
- Nospread/norecoil probability model: weapon/range/movement buckets with rolling impossible-outcome scoring beyond starter event fields.
- Infected movement baselines: hunter, jockey, charger, ladder, water, incap, pounce/charge/ride exception tuning.
- RCON hardening: optional server-side RCON lock/allowlist if the hosting environment supports the required extension.

## False-positive stance

`orion_mode` defaults to `shadow`. Live bans are not a Phase 1 default. A threshold can move to alert/enforce only after a staging corpus proves normal competitive play, high-skill aim, high-skill movement, spectators, admins, and high-ping players remain below enforcement thresholds.
