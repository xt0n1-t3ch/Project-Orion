# Project Orion Agent Guide

## Commands

- Run static trainer analysis:
  - `python tools/analyze_reborn_trainer.py --trainer-root "D:\X\4-Gaming\Modding\L4D2 Server\L4D2 Reborn Trainer"`
- Run local Python validation:
  - `python -m unittest discover -s tests -p "test_*.py"`
- Compile SourcePawn locally when `spcomp` is installed:
  - `spcomp -E -w234 -w217 -O2 -v2 addons/sourcemod/scripting/orion.sp`

## Source layout

- `addons/sourcemod/scripting/orion.sp` is the compile entrypoint.
- `addons/sourcemod/scripting/orion/*.sp` contains included modules.
- `cfg/sourcemod/orion.cfg` is the default server config.
- `docs/research/` contains threat intelligence and static analysis.
- `tools/` contains safe, non-executing analysis helpers.

## Done criteria

- SourcePawn compiles with zero warnings on SourceMod 1.11, 1.12, and 1.13 in CI.
- Static analysis accounts for every file in the trainer directory without executing binaries.
- Enforcement remains disabled by default; `orion_mode` defaults to `shadow`.
- Any ban path must be evidence-backed and configurable.

## Safety boundaries

- Never commit cheat binaries, archives, credentials, server logs, or player PII.
- Do not execute downloaded or local cheat samples.
- BLACKWATCH deployment is a separate staging step after Orion compiles and shadow-mode evidence is reviewed.
