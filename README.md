# Open-World Racing Game

This repository is the production home for a single-player, realistic-simcade open-world racing game built with Godot 4 Forward+.

The repository name is historical and does not define the game title, setting, or genre.

## Supported development platforms

Windows and Linux are supported together from the beginning. The same Godot project, scenes, GDScript, resources, tests, and gameplay systems are used on both platforms. Platform-specific work is limited to native verification wrappers, export presets, packaging, and final hardware testing.

- Windows 10 or later
- Modern x86_64 Linux distribution
- Godot 4.7.x with Forward+ support
- PowerShell 5.1+ on Windows or Bash on Linux

The platform decision is recorded in `docs/decisions/2026-08-06-windows-linux-support.md` and supersedes the earlier Windows-only wording in the initial design snapshot.

## Approved direction

- Open-world career and free-roam structure
- Grounded presentation with selective road, rally, drift, street, and endurance motorsport
- Serious simcade handling with believable weight, grip, suspension, braking, drivetrain differences, tuning, and damage
- Fictional mixed-international world with mountains, countryside, forest, highways, desert, coast, limited cities, towns, and industrial areas
- Vehicle-only civilian traffic; no pedestrians
- Light police presence
- Dynamic day/night and basic weather
- Keyboard-first controls with controller support
- Automatic and manual transmission
- Chase, hood, bumper, and cockpit cameras
- Any useful development asset may be used

## Development strategy

Development starts with a polished 4–6 km² mountain-and-countryside vertical slice, backed by production-grade modular systems. The full world target is approximately 15–25 km².

## Verify locally

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify\verify.ps1
```

Linux:

```bash
./tools/verify/verify.sh
```

Both wrappers import the project headlessly and run the same test contracts. They do not use GitHub Actions.

## Repository documents

- Design specification: `docs/superpowers/specs/2026-08-06-open-world-racing-game-design.md`
- Platform amendment: `docs/decisions/2026-08-06-windows-linux-support.md`
- Phase 0 plan: `docs/superpowers/plans/2026-08-06-phase-0-foundation.md`

## Current status

The clean Godot baseline is verified. Phase 0 now includes the application event boundary, structured session logging, and matching Windows/Linux local verification entrypoints.
