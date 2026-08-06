# Open-World Racing Game

This repository is the production home for a single-player, realistic-simcade open-world racing game built with Godot 4.7.1 Forward+ for Windows x86_64 and Linux x86_64.

The repository name is historical and does not define the final game title, setting, or genre.

## Product direction

- Seamless free roam with a sandbox career
- Serious simcade handling with believable weight, grip, suspension, braking, gearing, drivetrain differences, tuning, assists, and mechanical damage
- Fictional mixed-international world emphasizing mountains, countryside, forests, highways, desert, coast, rural settlements, and limited city space
- Circuit, sprint, rally, off-road, drift, drag, time-trial, endurance, and selected street events
- Vehicle-only civilian traffic; no pedestrians
- Light police presence
- Dynamic day/night, rain, wet roads, and fog
- Keyboard-first controls with full controller support
- Automatic and manual transmission
- Chase, hood, bumper, and cockpit cameras
- Any useful development asset may be evaluated; the asset registry records its source and production readiness

## Development strategy

Development starts with a polished 4–6 km² mountain-and-countryside vertical slice backed by production-grade modular systems. The eventual world target is approximately 15–25 km².

The first playable region targets one polished rear-wheel-drive sports coupe, three to five traffic vehicles, one named rival, a garage, a dealership, five event types, progression, tuning, damage, saving, traffic, day/night, and weather.

## Graphics direction

The project pursues AAA qualities where they produce visible value: coherent physically based materials, high-quality hero vehicles, strong lighting and weather, disciplined composition, stable frame pacing, controlled shader permutations, asset LODs, and measurable performance.

The renderer is Forward+ only. Production content is authored against a developer-only Cinematic reference profile and scaled through Low, Medium, High, and Ultra gameplay profiles. Cinematic is not a minimum-hardware promise.

Primary runtime target:

- 1920×1080
- 60 FPS
- GTX 1660 / RX 580-class hardware
- Appropriate graphics profile and resolution scaling

Only physical-hardware results may be used for final performance claims. Headless runs validate contracts and report structure, not GPU performance.

## Phase 0 status

Phase 0 provides:

- Windows and Linux verification wrappers driven by one shared test manifest
- Structured logging and application event boundary
- Typed settings and input profiles
- Keyboard and controller input shaping
- Five graphics profiles and a central runtime quality service
- Versioned atomic saves with backup and corruption recovery
- Auditable asset registry and production-budget validation
- Graphics laboratory, open-world proxy, and shader pipeline warm-up workloads
- Benchmark reporting with pipeline compilation counters
- Windows and Linux export contracts with shader baking
- Graphics, material, LOD, lighting, and performance standards

See `docs/status/phase-0-report.md` for the exact verification state and hardware-only checks that remain.

## Important documents

- Master game design: `docs/superpowers/specs/2026-08-06-open-world-racing-game-design.md`
- AAA graphics foundation design: `docs/superpowers/specs/2026-08-06-aaa-graphics-foundation-design.md`
- Phase 0 implementation plan: `docs/superpowers/plans/2026-08-06-phase-0-aaa-foundation.md`
- Graphics and asset standard: `docs/standards/graphics-and-assets.md`
- Asset-tool reconnaissance: `docs/research/asset-candidates.md`
- Phase 0 report: `docs/status/phase-0-report.md`

## Requirements

- Godot 4.7.1
- Vulkan-capable desktop GPU for Forward+
- Windows 10 or later, or a modern x86_64 Linux distribution
- PowerShell 5.1+ on Windows
- Bash on Linux

## Verify on Linux

```bash
GODOT_BIN=/path/to/Godot_v4.7.1-stable_linux.x86_64 \
  ./tools/verify/verify.sh --benchmark
```

## Verify on Windows

```powershell
$env:GODOT = "C:\path\to\Godot_v4.7.1-stable_win64.exe"
powershell -ExecutionPolicy Bypass -File .\tools\verify\verify.ps1 -Benchmark
```

Both wrappers import the project and execute every test listed in `tests/test_manifest.txt`. No GitHub Actions workflow is used.

## Export contracts

`export_presets.cfg` defines:

- `Windows Desktop` → `build/windows/OpenWorldRacing.exe`
- `Linux` → `build/linux/OpenWorldRacing.x86_64`

Export templates are required to produce binaries. Export contract tests do not require templates and therefore run in the standard verification suite.
