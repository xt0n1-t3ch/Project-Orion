# Project Orion

Project Orion is a server-side Left 4 Dead 2 anti-cheat for competitive SourceMod servers. It is designed as the BLACKWATCH replacement path for Lilac/SMAC checks, with shadow-mode validation before enforcement.

Phase 1 focuses on static cheat dissection, threat-intel mapping, server-side evidence scoring, and safe data-minimization controls. Enforcement is evidence-based and disabled by default until a staging corpus proves thresholds are reliable.

## Phase 1 surfaces

- Static, non-executing analysis of Reborn-style trainer samples.
- `orion_visibility_guard` for ghost infected data minimization.
- `orion_aim_analyzer` for silent/perfect/humanized aim evidence.
- `orion_movement_analyzer` for bhop, macro, fakelag, and tick anomalies.
- `orion_integrity` for interpolation, client cvar, ping/loss, chat-clear, and invalid-name evidence.
- `orion_evidence` for structured admin-reviewable logs.

## Validation

```powershell
python -m unittest discover -s tests -p "test_*.py"
spcomp -E -w234 -w217 -O2 -v2 addons/sourcemod/scripting/orion.sp
```

See `docs/index.md` for the complete workflow.
