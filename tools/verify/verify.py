#!/usr/bin/env python3
"""Import and test the STRATOSPHERE Godot project from a clean checkout."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def resolve_godot() -> str:
    configured = os.environ.get("GODOT_BIN")
    candidates = [configured, shutil.which("godot"), shutil.which("godot4")]

    if os.name == "nt":
        candidates.extend(
            [
                r"C:\Tools\Godot\godot.exe",
                r"C:\Tools\Godot\Godot_v4.7.1-stable_win64.exe",
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
        "Godot 4.7.1 was not found. Set GODOT_BIN or add godot/godot4 to PATH."
    )


def run(command: list[str], label: str) -> None:
    print(f"\n== {label} ==")
    print(" ".join(command))
    completed = subprocess.run(command, cwd=ROOT, check=False)
    if completed.returncode != 0:
        raise RuntimeError(f"{label} failed with exit code {completed.returncode}")


def main() -> int:
    try:
        godot = resolve_godot()
        run(
            [godot, "--headless", "--path", str(ROOT), "--editor", "--quit"],
            "Godot import",
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
        )
    except (FileNotFoundError, RuntimeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("\nVerification complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
