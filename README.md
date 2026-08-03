# STRATOSPHERE: Frontier Vector

A simulation-first single-player planetary VTOL game built with Godot and Blender.

Phase 0–1 proves the central promise before the project expands: the craft must already be satisfying to take off, hover, vector into forward flight, fly a route, switch cameras, land, crash, and restart.

## Requirements

- Godot 4.6.3 stable
- Python 3.12 or newer
- PowerShell 7 on Windows
- Blender 5.2-compatible Python API for generated vehicle assets

## Verify

Windows:

```powershell
pwsh ./tools/verify/verify.ps1
```

Cross-platform:

```bash
python tools/verify/verify.py
```

The verifier checks the repository contract, generated-asset manifest, Blender Python syntax, Godot import output, and the complete headless test suite. Set `GODOT_BIN` when Godot is not available as `godot`, `godot4`, or `C:\Tools\Godot\godot.exe`.

## Play

```powershell
C:\Tools\Godot\godot.exe --path .
```

The main scene is `scenes/flight_room/flight_room.tscn`.

### Controls

| Input | Action |
| --- | --- |
| Mouse | Pitch and yaw |
| Q / E | Roll left / right |
| Space / Ctrl | Raise / lower collective |
| X / Z | Vector toward forward flight / hover |
| F / H | Translate left / right |
| R / V | Translate up / down |
| Shift | Aerodynamic brake |
| C | Toggle chase / cockpit camera |
| F5 | Restart route |
| Escape | Release mouse |
| Mouse click | Recapture mouse |

## Generate the VTOL asset

The repository retains a primitive visual fallback, so the game remains importable without Blender. Generate the original hard-surface source and runtime model with:

```powershell
blender --background --python tools/blender/generate_vtol_blockout.py
```

Generate six inspection renders as well:

```powershell
blender --background --python tools/blender/generate_vtol_blockout.py -- --render-previews
```

Outputs:

- `assets/source/vtol_blockout.blend`
- `assets/generated/vtol_blockout.glb`
- optional previews in `assets/generated/previews/vtol_blockout/`

The contract for scale, axes, license, generation paths, and required gameplay anchors is stored in `assets/generated/vtol_blockout.asset.json`.

## Export Windows

With Godot Windows export templates installed:

```powershell
python tools/verify/verify.py --export-windows
```

Output:

- `build/windows/STRATOSPHERE.exe`
- `build/windows/STRATOSPHERE.pck`

The narrowly triggered `Windows Prototype Build` workflow verifies the project, performs the cross-platform Windows export, and retains a downloadable artifact for 14 days.

## Implemented in Phase 0–1

- 120 Hz deterministic simulation baseline
- Momentum-preserving physical VTOL model
- Continuous hover-to-forward thrust vectoring
- Keyboard-and-mouse pilot input
- Cockpit and craft-relative chase cameras
- Ordered three-gate route
- Designated landing zone, crash state, and deterministic restart
- Telemetry HUD and control hints
- Procedural engine hum, wind noise, and exhaust feedback
- 400×800 meter frontier test environment with runway lighting and large landmarks
- Source-controlled Blender VTOL generator and asset manifest
- Clean-checkout verification and Windows export preset

## Deliberately deferred

Open-world streaming, economy, progression, combat, dynamic weather, final vehicle art, orbital flight, moons, campaign content, and advanced damage remain separate later milestones.