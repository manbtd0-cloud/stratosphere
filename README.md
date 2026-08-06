# Open-World Racing Game

This repository is the production home for a Windows-only, single-player, realistic-simcade open-world racing game built with Godot 4 Forward+.

The repository name is historical and does not define the game title, setting, or genre.

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

The initial playable slice targets:

- One polished rear-wheel-drive sports coupe
- Three to five traffic vehicles
- One named rival
- Garage and dealership
- Circuit, sprint, rally, drift, and time-trial events
- Economy, reputation, tuning, upgrades, damage, repair, saving, weather, and traffic

## Repository documents

- Design specification: `docs/superpowers/specs/2026-08-06-open-world-racing-game-design.md`
- Phase 0 plan: `docs/superpowers/plans/2026-08-06-phase-0-foundation.md`

## Requirements

- Windows 10 or later
- Godot 4.7.x with Forward+ support
- PowerShell 5.1 or later

## Verify the baseline

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify\verify.ps1
```

The script imports the project headlessly and runs the smoke-test contract. It does not use GitHub Actions.

## Current status

The previous repository contents were intentionally removed in one recoverable Git commit. This clean baseline begins Phase 0 of the approved racing-game design.
