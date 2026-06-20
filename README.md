# Project Orion

Project Orion is a server-side Left 4 Dead 2 anti-cheat for competitive SourceMod servers. It is designed as the BLACKWATCH replacement path for Lilac/SMAC checks, with shadow-mode validation before enforcement.

Project Orion uses static cheat dissection, threat-intel mapping, server-side evidence scoring, and safe data-minimization controls. Enforcement is evidence-based and disabled by default until a staging corpus proves thresholds are reliable.

## Detection surfaces

- Static, non-executing analysis of Reborn-style trainer samples.
- `orion_visibility_guard` for ghost/inactive infected data minimization and PVS-hidden enemy evidence.
- `orion_usercmd_guard` for SMAC-style usercmd reuse, regression, tick mutation, and impossible-angle evidence.
- `orion_aim_analyzer` for silent/perfect/humanized aim, snap history, autoshoot, and starter weapon-outcome evidence.
- `orion_movement_analyzer` for bhop, macro, speedhack, fakelag/choke, latency-aware tick drift, and movement anomalies.
- `orion_cvar_policy` plus `orion_integrity` for data-driven client cvar policy, interpolation, ping/loss, chat-clear, and invalid-name evidence.
- `orion_abuse_guard` for command-rate, dangerous command, and name-change abuse evidence.
- `orion_evidence` for structured admin-reviewable logs.

## Validation

```powershell
python -m unittest discover -s tests -p "test_*.py"
spcomp -E -w234 -w217 -O2 -v2 addons/sourcemod/scripting/orion.sp
```

See `docs/index.md` for the complete workflow.
