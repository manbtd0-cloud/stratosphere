#!/usr/bin/env python3
"""Build the STRATOSPHERE VTOL with Godot-native orientation.

Run from the repository root:

    blender --background --python tools/blender/build_vtol_blockout.py

The geometry module owns the single export-root half-turn that maps the authored
Blender -Y nose to Godot -Z. This orchestrator verifies that contract, then saves
and exports the reproducible Blender and GLB assets.
"""

from __future__ import annotations

import sys
from pathlib import Path

import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import generate_vtol_blockout as geometry


def verify_godot_orientation(root: bpy.types.Object) -> None:
    expected = geometry.HALF_TURN_RADIANS
    if abs(root.rotation_euler.z - expected) > 1e-6:
        raise RuntimeError(
            "VTOL export root must carry exactly one half-turn around Blender Z"
        )

    root["forward_axis_after_gltf_export"] = "-Z"
    root["up_axis_after_gltf_export"] = "+Y"
    root["axis_conversion"] = "Half-turn around Blender Z at export root"


def main() -> None:
    args = geometry.parse_args()
    geometry.reset_scene()
    geometry.configure_scene()
    root = geometry.build_vtol()
    verify_godot_orientation(root)
    geometry.save_outputs(root)
    if args.render_previews:
        geometry.render_previews(root)
    print(f"Blender version: {bpy.app.version_string}")
    print(f"Saved corrected Blender source: {geometry.SOURCE_BLEND}")
    print(f"Saved corrected Godot runtime GLB: {geometry.RUNTIME_GLB}")


if __name__ == "__main__":
    main()