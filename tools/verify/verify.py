#!/usr/bin/env python3
"""Import and test the STRATOSPHERE Godot project from a clean checkout."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

FORBIDDEN_OUTPUT_MARKERS = (
    "SCRIPT ERROR:",
    "ERROR:",
    "ObjectDB instances leaked",
    "resources still in use at exit",
    "Pages in use exist at exit",
)


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


def main() -> int:
    try:
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
    except (FileNotFoundError, RuntimeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("\nVerification complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
