# STRATOSPHERE: Frontier Vector

A simulation-first single-player planetary VTOL game built with Godot and Blender.

Phase 0–1 proves the central promise before the project expands: the craft must already be satisfying to take off, hover, vector into forward flight, fly a route, switch cameras, land, crash, and restart.

## Requirements

- Godot 4.6.3 stable
- Python 3.12 or newer
- PowerShell 7 on Windows
- Blender 3.4 or newer for generated vehicle assets

## Verify

Windows:

```powershell
pwsh ./tools/verify/verify.ps1
```

Cross-platform:

```bash
python tools/verify/verify.py
```

The verifier checks the repository contract, generated-asset manifest, Blender Python syntax, Godot import output, all headless tests, and a real gameplay-scene smoke run. Set `GODOT_BIN` when Godot is not available as `godot`, `godot4`, or `C:\Tools\Godot\godot.exe`.

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

The editable `.blend` source and Godot-ready `.glb` are generated from source-controlled geometry. Use the canonical builder, which applies and verifies the Blender-to-Godot axis conversion exactly once:

```powershell
blender --background --python tools/blender/build_vtol_blockout.py
```

Generate six inspection renders as well:

```powershell
blender --background --python tools/blender/build_vtol_blockout.py -- --render-previews
```

Outputs:

- `assets/source/vtol_blockout.blend`
- `assets/generated/vtol_blockout.glb`
- optional previews in `assets/generated/previews/vtol_blockout/`

Godot uses the generated GLB as the in-game craft visual while collision, cameras, physics, and feedback remain independently controlled by the craft scene. The contract for scale, axes, licensing, generation paths, and required anchors is stored in `assets/generated/vtol_blockout.asset.json`.

## Export Windows

With Godot Windows export templates installed:

```powershell
python tools/verify/verify.py --export-windows
```

Output:

- `build/windows/STRATOSPHERE.exe`
- `build/windows/STRATOSPHERE.pck`

The `Phase 0-1 Verify` workflow imports the project, runs the complete verification gate, performs the cross-platform Windows export, and retains a downloadable artifact for 14 days.

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
- Generated Blender VTOL source and Godot runtime model
- Clean-checkout tests, gameplay smoke verification, and Windows export

## Deliberately deferred

Open-world streaming, economy, progression, combat, dynamic weather, final vehicle art, orbital flight, moons, campaign content, and advanced damage remain separate later milestones.