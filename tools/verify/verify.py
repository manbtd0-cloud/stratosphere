#!/usr/bin/env python3
"""Verify STRATOSPHERE from a clean checkout and optionally export Windows."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

REQUIRED_PATHS = (
    "project.godot",
    "export_presets.cfg",
    "scenes/flight_room/flight_room.tscn",
    "scenes/flight_room/flight_room_environment.tscn",
    "scenes/craft/frontier_vtol.tscn",
    "scenes/craft/flight_camera_rig.tscn",
    "scenes/ui/flight_hud.tscn",
    "scripts/flight/flight_model.gd",
    "scripts/flight/frontier_vtol_controller.gd",
    "scripts/flight/flight_feedback.gd",
    "scripts/flight/procedural_audio_player_3d.gd",
    "scripts/input/pilot_input_adapter.gd",
    "scripts/camera/flight_camera_rig.gd",
    "scripts/game/flight_room_controller.gd",
    "scripts/validation/asset_manifest_validator.gd",
    "scripts/validation/project_contract_validator.gd",
    "assets/generated/vtol_blockout.asset.json",
    "assets/generated/vtol_blockout.glb",
    "assets/source/vtol_blockout.blend",
    "tools/blender/build_vtol_blockout.py",
    "tools/blender/generate_vtol_blockout.py",
    "tests/test_runner.gd",
    "tests/gameplay_smoke_runner.gd",
)

GENERATED_ASSET_PATHS = (
    "assets/generated/vtol_blockout.glb",
    "assets/source/vtol_blockout.blend",
)

BLENDER_SCRIPT_PATHS = (
    "tools/blender/build_vtol_blockout.py",
    "tools/blender/generate_vtol_blockout.py",
)

FORBIDDEN_OUTPUT_MARKERS = (
    "SCRIPT ERROR:",
    "ERROR:",
    "ObjectDB instances leaked",
    "resources still in use at exit",
    "Pages in use exist at exit",
)

EXPECTED_MAIN_SCENE = 'run/main_scene="res://scenes/flight_room/flight_room.tscn"'
EXPECTED_PHYSICS_TICKS = "common/physics_ticks_per_second=120"
EXPECTED_EXPORT_PRESET = 'name="Windows Desktop"'
EXPECTED_EXPORT_PATH = 'export_path="build/windows/STRATOSPHERE.exe"'
EXPECTED_ASSET_GENERATOR = "tools/blender/build_vtol_blockout.py"
MAX_GENERATED_FILE_BYTES = 100 * 1024 * 1024
WINDOWS_OUTPUT = ROOT / "build" / "windows" / "STRATOSPHERE.exe"
WINDOWS_PCK = ROOT / "build" / "windows" / "STRATOSPHERE.pck"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--export-windows",
        action="store_true",
        help="Export the verified project with the Windows Desktop preset.",
    )
    return parser.parse_args()


def resolve_godot() -> str:
    configured = os.environ.get("GODOT_BIN")
    candidates = [configured, shutil.which("godot"), shutil.which("godot4")]

    if os.name == "nt":
        candidates.extend(
            [
                r"C:\Tools\Godot\godot.exe",
                r"C:\Tools\Godot\Godot_v4.6.3-stable_win64.exe",
            ]
        )

    for candidate in candidates:
        if not candidate:
            continue
        path = Path(candidate)
        if path.exists():
            return str(path)
        resolved = shutil.which(candidate)
        if resolved:
            return resolved

    raise FileNotFoundError(
        "Godot 4.6.3 stable was not found. Set GODOT_BIN or add godot/godot4 to PATH."
    )


def validate_repository_contract() -> None:
    errors: list[str] = []

    for relative_path in REQUIRED_PATHS:
        if not (ROOT / relative_path).is_file():
            errors.append(f"Missing required file: {relative_path}")

    for relative_path in GENERATED_ASSET_PATHS:
        asset_path = ROOT / relative_path
        if not asset_path.is_file():
            continue
        size = asset_path.stat().st_size
        if size <= 0:
            errors.append(f"Generated asset is empty: {relative_path}")
        if size > MAX_GENERATED_FILE_BYTES:
            errors.append(
                f"Generated asset exceeds 100 MB repository budget: {relative_path}"
            )

    project_path = ROOT / "project.godot"
    if project_path.is_file():
        project_text = project_path.read_text(encoding="utf-8")
        if EXPECTED_MAIN_SCENE not in project_text:
            errors.append("project.godot has the wrong main scene")
        if EXPECTED_PHYSICS_TICKS not in project_text:
            errors.append("project.godot must use 120 physics ticks per second")

    preset_path = ROOT / "export_presets.cfg"
    if preset_path.is_file():
        preset_text = preset_path.read_text(encoding="utf-8")
        if EXPECTED_EXPORT_PRESET not in preset_text:
            errors.append("Windows Desktop export preset is missing")
        if EXPECTED_EXPORT_PATH not in preset_text:
            errors.append("Windows Desktop export path is incorrect")

    manifest_path = ROOT / "assets" / "generated" / "vtol_blockout.asset.json"
    if manifest_path.is_file():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            errors.append(f"VTOL asset manifest is invalid JSON: {error}")
        else:
            if manifest.get("forward_axis") != "-Z":
                errors.append("VTOL asset manifest forward axis must be -Z")
            if manifest.get("up_axis") != "+Y":
                errors.append("VTOL asset manifest up axis must be +Y")
            if manifest.get("unit_scale_meters") != 1.0:
                errors.append("VTOL asset manifest unit scale must be 1.0 meter")
            if manifest.get("generator") != EXPECTED_ASSET_GENERATOR:
                errors.append(
                    "VTOL asset manifest must use the Godot-axis build orchestrator"
                )

    for relative_path in BLENDER_SCRIPT_PATHS:
        script_path = ROOT / relative_path
        if not script_path.is_file():
            continue
        source = script_path.read_text(encoding="utf-8")
        try:
            compile(source, str(script_path), "exec")
        except SyntaxError as error:
            errors.append(f"Blender script has invalid Python syntax: {error}")

    if errors:
        formatted = "\n".join(f"- {error}" for error in errors)
        raise RuntimeError(f"Repository contract failed:\n{formatted}")

    print(f"Repository contract passed: {len(REQUIRED_PATHS)} required files")


def find_forbidden_output(output: str) -> list[str]:
    return [marker for marker in FORBIDDEN_OUTPUT_MARKERS if marker in output]


def run(command: list[str], label: str, timeout_seconds: int) -> None:
    print(f"\n== {label} ==")
    print(" ".join(command))

    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            errors="replace",
            timeout=timeout_seconds,
        )
    except subprocess.TimeoutExpired as error:
        partial_output = error.stdout or ""
        if isinstance(partial_output, bytes):
            partial_output = partial_output.decode(errors="replace")
        if partial_output:
            print(partial_output, end="" if partial_output.endswith("\n") else "\n")
        raise RuntimeError(
            f"{label} timed out after {timeout_seconds} seconds"
        ) from error

    output = completed.stdout or ""
    if output:
        print(output, end="" if output.endswith("\n") else "\n")

    if completed.returncode != 0:
        raise RuntimeError(f"{label} failed with exit code {completed.returncode}")

    forbidden_markers = find_forbidden_output(output)
    if forbidden_markers:
        joined = ", ".join(forbidden_markers)
        raise RuntimeError(f"{label} emitted forbidden engine output: {joined}")


def export_windows(godot: str) -> None:
    WINDOWS_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    WINDOWS_OUTPUT.unlink(missing_ok=True)
    WINDOWS_PCK.unlink(missing_ok=True)

    run(
        [
            godot,
            "--headless",
            "--path",
            str(ROOT),
            "--export-release",
            "Windows Desktop",
            str(WINDOWS_OUTPUT),
        ],
        "Windows export",
        timeout_seconds=180,
    )

    if not WINDOWS_OUTPUT.is_file() or WINDOWS_OUTPUT.stat().st_size == 0:
        raise RuntimeError("Windows export did not produce STRATOSPHERE.exe")
    if not WINDOWS_PCK.is_file() or WINDOWS_PCK.stat().st_size == 0:
        raise RuntimeError("Windows export did not produce STRATOSPHERE.pck")

    print(
        "Windows export complete: "
        f"{WINDOWS_OUTPUT.relative_to(ROOT)} and {WINDOWS_PCK.relative_to(ROOT)}"
    )


def main() -> int:
    args = parse_args()
    try:
        validate_repository_contract()
        godot = resolve_godot()
        run(
            [godot, "--headless", "--path", str(ROOT), "--editor", "--quit"],
            "Godot import",
            timeout_seconds=120,
        )
        run(
            [
                godot,
                "--headless",
                "--path",
                str(ROOT),
                "--script",
                "res://tests/test_runner.gd",
            ],
            "Godot tests",
            timeout_seconds=60,
        )
        run(
            [
                godot,
                "--headless",
                "--verbose",
                "--path",
                str(ROOT),
                "--script",
                "res://tests/gameplay_smoke_runner.gd",
            ],
            "Gameplay scene smoke test",
            timeout_seconds=60,
        )
        if args.export_windows:
            export_windows(godot)
    except (FileNotFoundError, RuntimeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("\nVerification complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
