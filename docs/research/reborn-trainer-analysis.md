# Reborn Trainer Static Analysis

Trainer root: `D:\X\4-Gaming\Modding\L4D2 Server\L4D2 Reborn Trainer`

Analysis date: 2026-06-20

This report is based on static inspection only. No trainer binary was executed.

## File inventory

| File | Kind | Size | SHA-256 |
|---|---:|---:|---|
| `dependencies.zip` | zip | 60,509,622 | `4A57399639C21181EE142A0D7CCD2945955AF205CDA745803ABD5903947DCC6B` |
| `MD5 Changer.exe` | PE | 346,624 | `6F126640355F40B31427C259A12E626F21A2498C510628877E013EACE4DFD026` |
| `readme.txt` | text | 482 | `4F3747EC13862661983D2427A9B771A56DC91BE7598C26A074D4D651019B3028` |
| `SKernelInjector.exe` | PE | 16,312 | `AC2E9354B49B52D6E940E76776A65859B1F96E4B20AAFBC6F43745B0A0B0BBD5` |
| `VR.dll` | PE | 2,469,376 | `1DCE3047CD20CF161C0D8A609041B5E2129CD4911F5471A9752106004D4C6D0C` |

## Structure findings

### `dependencies.zip`

The archive contains Chromium Embedded Framework-style UI/runtime dependencies:

- `chrome_elf.dll`
- `d3dcompiler_47.dll`
- `icudtl.dat`
- `libcef.dll`
- `ProcessHelper.exe`
- `SDL2.dll`
- `snapshot_blob.bin`
- `v8_context_snapshot.bin`
- `cef.pak`
- `README.txt`
- `en-US.pak`

Defensive meaning: this is likely menu/UI support, not the primary cheat logic. Orion should not waste effort on CEF signatures because `MD5 Changer.exe` exists and server-only SourceMod cannot inspect these files.

### `SKernelInjector.exe`

Observed strings/import-like evidence:

- `Successfully injected, Please close this window!`
- `Injection failed!`
- `LoadLibraryA`
- `WriteProcessMemory`
- `CreateRemoteThread`
- `IsDebuggerPresent`
- PDB path: `D:\l4d2\Win32\Release\SKernelInjector.pdb`

Defensive meaning: this is a classic DLL injection loader. A game server will not reliably see this loader, and weak file/hash signatures are easy to evade. Orion must detect the behavior produced after injection.

### `VR.dll`

Observed feature clusters:

- Aim: `Aimbot`, `Silent`, `Perfect Silent`, `Humanized`, `Aimbot Bone`, `Bestbone`, `Always Silent`, `Silent Autoshove`, `Autoknife`, and warnings that fake-team/fakelag/nospread conflict with silent aim.
- Visuals: `Chams`, `Extended Chams`, `Glow`, `EntityGlowEffects`, `RenderGlowModels`, `MaterialHack conflicts with Glow`, `DME Chams conflict with Glow`, `Hitboxes`, and `Hitbox face alpha colors`.
- Weapon manipulation: `No Spread`, `Minigun No Spread`, `No Recoil`, `No Visual Recoil`, `Rapid Fire`, `Always Recoil/Spread/Rapid fire`, and text that nospread makes bullets pinpoint-accurate.
- Movement/exploit: `Bunnyhop`, `Humanized bhop`, `Rage Bunnyhop`, `Strafe`, `Fakelag`, `Backtrack`, `Fake Angle`, `Teleport`, `Spawn anywhere in Versus mode`, and `Hold Lagexploit hotkey until you near humans`.
- Game state: `client.dll`, `m_hActiveWeapon`, `m_hMyWeapons`, L4D2 weapon class strings such as `weapon_jockey_claw`, `weapon_charger_claw`, `weapon_smg_silenced`, `weapon_rifle_sg552`, and `weapon_smg_mp5`.
- Observation evasion: `Anti-OBS##1` through `Anti-OBS##14`, `Anti Discord`, and notes about non-Steam versions only supporting visuals.

Focused string counts from `VR.dll`:

| Term | Count |
|---|---:|
| `Aimbot` | 35 |
| `Silent` | 29 |
| `Perfect Silent` | 7 |
| `Nospread` / `No Spread` | 19 |
| `No Recoil` | 1 |
| `Bunnyhop` / `Humanized bhop` | 5 |
| `Strafe` | 5 |
| `Fakelag` | 3 |
| `Backtrack` | 26 |
| `Glow` | 36 |
| `Chams` | 41 |
| `Anti-OBS` | 20 |
| `Fake Angle` | 10 |
| `Teleport` | 9 |
| `Rapid Fire` | 3 |
| `Autoshove` | 10 |

Defensive meaning: this trainer spans render overlays, aim manipulation, weapon outcome manipulation, and movement/exploit assistance. Orion needs multiple independent evidence channels rather than a single aimbot detector.

### `MD5 Changer.exe`

The tool name and included instructions say to run the MD5 changer against the injector periodically. Defensive meaning: file hashes are intentionally unstable and are not a reliable server-side control.

## Capability matrix

| Cheat feature | Client mechanism inferred from static evidence | Server observable | Orion control |
|---|---|---|---|
| DLL injection | `LoadLibraryA`, `WriteProcessMemory`, `CreateRemoteThread` loader | none directly | do not signature-match; detect outcomes |
| ESP / glow / chams | reads entity data and draws overlays through game/render hooks | only possible if server transmits useful entity state | `orion_visibility_guard`; reaction/awareness evidence |
| Silent aim | command/view manipulation with target hit despite non-human aim transition | attack windows, angle deltas, target switch timing, hit/death correlation | `orion_aim_analyzer` |
| Perfect silent aim | stronger variant with hidden crosshair movement | repeated one-tick acquisition and hit correlation | `orion_aim_analyzer` high-confidence tier |
| Humanized aim | smoothed aim assist to avoid snap checks | long-window target tracking consistency and unlikely acquisition rates | rolling aim score with decay |
| Nospread | client command/seed/weapon manipulation or prediction abuse | improbable hit clusters by weapon/range/movement | hurt/death correlation, airborne/fast-shot scoring, and future weapon-probability corpus |
| No recoil | view/recoil compensation | less visible than nospread; detectable statistically over repeated fire | long-window weapon outcome scoring |
| Auto-bhop / macro | timed jump input and strafe assistance | usercmd buttons, flags, speed, ground contact | `orion_movement_analyzer` |
| Fakelag / backtrack | tick/latency/interp manipulation | tickcount repeats, lerp/interp values, impossible hit windows | movement + integrity analyzer |
| Fake angles / spin | manipulated usercmd view angles | impossible pitch/roll, mouse/angle mismatch | angle guard and aim evidence |
| Chat/name abuse | chat-clear payloads and invalid display names | SourceMod chat/name hooks | integrity guard |
| Anti-OBS / Discord | overlay capture hiding | not server-side observable | server evidence only |

## Requirements derived for Orion

- Ban decisions must be rolling-score based, not single-event based.
- Evidence must include enough context for admin review: target, tick, angle, mouse, velocity, cvar value, and map.
- Visibility suppression must be safe and narrow. Blocking ghost infected from survivors is high-value and low-risk; blocking all infected data would break gameplay.
- Nospread and humanized aim need statistical treatment; a single unlikely shot is not enough.
- Default mode must remain `shadow` until BLACKWATCH has a clean validation corpus.
