# L4D2 Cheat Threat Intelligence

Research date: 2026-06-20

This report summarizes public threat intelligence used to design Project Orion Phase 1. It is defensive and maps observed cheat claims to server-side controls.

## Source ledger

| Source | Evidence | Defensive conclusion |
|---|---|---|
| CS-Junkies `Left4Dead2 Visuals Multihack` thread | Thread shows a long-running Reborn/Visuals community with hundreds of pages. Page 44 discusses nospread/no recoil detectability, config storage under the L4D2 folder, and method differences. | Nospread detection is an active community concern; Orion needs weapon outcome scoring and cannot rely on fixed signatures. |
| CS-Junkies download page `mydownloads.php?action=view_down&did=95` | Direct reader returned 403. Search results identify it as the Visuals/Reborn download path. | Treat as active but access-restricted; rely on accessible thread pages and local trainer sample. |
| UnknownCheats L4D2 tutorial post | Single-post reader identifies a 2024 tutorial titled `AIMBOT / ESP / SILENTAIM / BHOP / SPEEDHACK`. | Cheat bundles commonly combine aim, visuals, movement, and speed; Orion modules must be independent and composable. |
| YouGame RU search results | Results include L4D2 `ESP, Wallhack, Aimbot`, private `Predator` style WH/AIM listings, and separate bhop threads. | RU marketplace vocabulary matches Reborn feature classes; Orion should support WH/AIM/BHOP controls. |
| Chinese search results | Results include 求生之路2 透视/自瞄 menu posts, Dunt0 listings with wallhack/ESP/aimbot/triggerbot/bhop/spinbot, and L4D2 autobhop tooling. | CN ecosystem confirms the same feature clusters and injection/menu workflow. |
| LILAC README | LILAC lists angle cheats, invalid convars, bhop, basic projectile/hitscan aimbot, aimlock, max interp, backtrack patch, macro detection, max ping, invalid names, and chat-clear fixes; it also says it is bypassable to an extent. | Orion must replace the useful public Lilac coverage with L4D2-specific evidence, data minimization, safer defaults, and shadow-mode proof before enforcement. |
| SMAC README/source | SMAC has modules for aimbot, wallhack, cvars, speedhack, spinhack, command/RCON monitoring, and L4D2 fixes; SMAC wallhack uses visibility/PVS-style transmission controls. | Orion should absorb the L4D2-relevant SMAC classes while avoiding broad legacy modules that produce noise or are not useful for this server. |
| SourceMod `OnPlayerRunCmd` API | Exposes buttons, angles, weapon, tickcount, seed, and mouse deltas. | Core telemetry surface for aim/movement/tick anomaly scoring. |

## Feature taxonomy

### Visual cheats: ESP, wallhack, glow, chams

Common claims: entity outlines, infected/survivor visibility through walls, glow model rendering, hitbox or material modifications.

Server-side control:

- suppress ghost infected data to survivors;
- avoid transmitting inactive/non-actionable infected state where safe;
- log impossible awareness patterns instead of trusting screenshots.

### Aim cheats: aimbot, silent aim, perfect silent, humanized aim

Common claims: normal aim, silent aim, perfect silent, smooth/humanized aim, best-bone selection, autoshoot/triggerbot.

Server-side control:

- score attack-start windows;
- correlate target acquisition to hurt/death events;
- use mouse delta and angle delta mismatches;
- use decay so one event does not ban a player.

### Weapon cheats: nospread, norecoil, rapidfire

Common claims: pinpoint accuracy, no recoil, method variants, detectability differences on community servers.

Server-side control:

- compare repeated hit results against expected weapon/range/movement context;
- prioritize repeated improbable clusters;
- avoid one-shot enforcement.

### Movement and exploit cheats: bhop, fakelag, speed, teleport, spawn exploit

Common claims: auto-bhop, speedhack, lag exploit/fakelag, spawn-anywhere assistance.

Server-side control:

- score jump timing and velocity gain;
- score repeated tickcount anomalies;
- enforce interpolation/lerp bounds;
- retain matchmode context for review.

## Defensive design decisions

1. **Server-only, evidence-first.** Orion does not inspect local processes. It detects the behavior that matters to competitive integrity.
2. **Shadow by default.** Enforcement waits until BLACKWATCH has zero false positives in the validation corpus.
3. **Multi-signal scoring.** Aim, movement, integrity, and visibility evidence are independent. One module can flag without forcing a ban.
4. **Data minimization beats ESP.** If the server does not transmit ghost infected state, local glow/chams cannot render that hidden state.
5. **Statistical controls for humanized cheats.** Humanized aim and no recoil need long-window scoring, not single-snap checks.

## Replacement parity matrix

| Legacy check | Orion replacement |
|---|---|
| Lilac angle-cheats / SMAC spinhack | invalid pitch/roll scoring in `orion_aim_analyzer`; command-angle evidence logged before enforcement |
| Lilac chat-clear and invalid chat characters | `orion_integrity` blocks control-character or excessive chat payloads |
| Lilac invalid convar detector / SMAC cvars | `orion_integrity` queries interpolation, prediction, lag compensation, `sv_cheats`, `mat_wireframe`, and `r_drawothermodels` |
| Lilac max interp and backtrack patch | interpolation cvar scoring plus command tick drift scoring |
| Lilac max ping | configurable ping/loss scoring, disabled by default until BLACKWATCH decides the competitive threshold |
| Lilac bhop/macro | jump-window streaks, speed gain, air-strafe burst, and command timing evidence |
| Lilac aimbot/autoshoot/aimlock / SMAC aimbot | attack-window, one-tick autoshoot, target acquisition, mouse/angle mismatch, hurt/death correlation |
| SMAC wallhack / L4D2 no-ghost classes | survivor-side suppression of ghost or dead infected transmit where safe |

## Open research lanes

- Fetch CS-Junkies protected download metadata through an authenticated browser session if Tony wants direct page capture.
- Build a larger corpus from demos/scrims to tune aim and movement scores.
- Add optional tournament-client attestation in Phase 2 if server-only evidence is not strict enough for high-stakes events.
