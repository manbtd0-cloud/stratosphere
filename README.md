# STRATOSPHERE: Frontier Vector

A simulation-first single-player planetary VTOL game built with Godot 4 and Blender.

The current milestone is the Phase 0–1 flight-room prototype: prove that the craft itself is worth playing before expanding into the open world.

## Requirements

- Godot 4.7.1
- Python 3.12 or newer
- PowerShell 7 on Windows
- Blender 5.2 when generated vehicle assets are introduced

## Verify

```powershell
pwsh ./tools/verify/verify.ps1
```

The verifier resolves Godot through `GODOT_BIN`, `godot`, `godot4`, or the standard project development path `C:\Tools\Godot\godot.exe`.

## Run

```powershell
godot --path . --editor
```

The bootstrap scene is `scenes/flight_room/flight_room.tscn`.

## Current Status

- Game design specification committed
- Phase 0–1 implementation plan committed
- Godot project bootstrap in progress on `agent/phase-0-1-flight-room`

## Project Boundaries

This milestone contains one player craft, keyboard-and-mouse controls, cockpit and chase cameras, one route, landing, crash/restart behavior, and automated verification. Multiplayer, on-foot gameplay, progression, combat, and open-world streaming remain outside this milestone.
