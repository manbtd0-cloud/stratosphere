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
| Mouse | Command smoothed pitch and yaw angular rate |
| Q / E | Smoothed roll left / right |
| Space / Ctrl | Raise / lower collective |
| X / Z | Vector toward forward flight / hover |
| F / H | Translate left / right |
| R / V | Translate up / down |
| Shift | Aerodynamic brake |
| C | Toggle chase / cockpit camera |
| F5 | Restart route |
| Escape | Release mouse |
| Mouse click | Recapture mouse |

## Control architecture

Pilot rotation commands are angular-rate demands, not direct percentages of raw torque. A bounded local-rate controller accelerates the craft toward the requested pitch, yaw, and roll rates, then actively removes angular velocity when input returns to neutral. It does not auto-level the craft and does not hold altitude.

The default keyboard-and-mouse profile is `resources/flight/default_flight_control_profile.tres`. Its current starting values are:

- full pitch demand: `950 px/s`
- full yaw demand: `1050 px/s`
- mouse response exponent: `1.35`
- hover max rates: `65 / 52 / 78 deg/s` pitch, yaw, roll
- forward max rates: `95 / 28 / 125 deg/s` pitch, yaw, roll
- rate gains: `210000 / 160000 / 240000 N·m per rad/s`
- torque limits: `220000 / 180000 / 260000 N·m`
- nominal hover collective: `0.74`
- hover detent window: `0.035`
- collective rate: `0.48 per second`
- vector input rate: `0.55 per second`
- chase FOV: `76–92 degrees`
- chase look-ahead: `0.28 seconds`, capped at `28 meters`

The collective detent only nudges an idle control near nominal hover; it does not inspect altitude or vertical speed. Thrust-vector transition follows a smoothed target. Chase view uses separate position and rotation responses, partial roll following, bounded velocity look-ahead, and speed-dependent FOV. These values are a tested architecture baseline, not a claim that final control tuning is complete.

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

The `Phase 0-1 Verify` workflow imports the project, runs the complete verification gate, performs the cross-platform Windows export, and retains a downloadable artifact for 14 days. It runs for `main`, pull requests into `main`, and isolated `agent/**` development branches.

## Implemented in Phase 0–1

- 120 Hz deterministic simulation baseline
- Momentum-preserving physical VTOL model
- Continuous hover-to-forward thrust vectoring
- Keyboard-and-mouse pilot input
- Bounded local angular-rate controller
- Smoothed mouse and keyboard rotational demand
- Idle hover-collective detent without altitude hold
- Cockpit and craft-relative chase cameras
- Speed-sensitive chase FOV and velocity look-ahead
- Ordered three-gate route
- Designated landing zone, crash state, and deterministic restart
- Telemetry HUD, control-demand cue, and control hints
- Procedural engine hum, wind noise, and exhaust feedback
- 400×800 meter frontier test environment with runway lighting and large landmarks
- Generated Blender VTOL source and Godot runtime model
- Clean-checkout tests, gameplay smoke verification, and Windows export

## Deliberately deferred

Open-world streaming, economy, progression, combat, dynamic weather, final vehicle art, orbital flight, moons, campaign content, advanced damage, gamepad/HOTAS support, control rebinding UI, and final control tuning remain separate later milestones.
