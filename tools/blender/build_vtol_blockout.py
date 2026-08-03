#!/usr/bin/env python3
"""Build the STRATOSPHERE VTOL with Godot-native orientation.

Run from the repository root:

    blender --background --python tools/blender/build_vtol_blockout.py

The geometry module authors its longitudinal axis in Blender's XY plane. This
orchestrator mirrors that axis before saving/exporting so the imported Godot
scene uses -Z forward and +Y up without a corrective runtime rotation.
"""

from __future__ import annotations

import sys
from pathlib import Path

import bmesh
import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import generate_vtol_blockout as geometry


def orient_for_godot(root: bpy.types.Object) -> None:
    """Mirror Blender Y so glTF import resolves the craft nose toward Godot -Z."""
    for obj in geometry.descendants(root):
        obj.location.y *= -1.0
        if obj.type != "MESH":
            continue

        mesh = obj.data
        for vertex in mesh.vertices:
            vertex.co.y *= -1.0

        edit_mesh = bmesh.new()
        edit_mesh.from_mesh(mesh)
        bmesh.ops.reverse_faces(edit_mesh, faces=list(edit_mesh.faces))
        edit_mesh.to_mesh(mesh)
        edit_mesh.free()
        mesh.update()

    root["forward_axis_after_gltf_export"] = "-Z"
    root["up_axis_after_gltf_export"] = "+Y"
    root["axis_conversion"] = "Mirrored Blender Y before glTF export"


def main() -> None:
    args = geometry.parse_args()
    geometry.reset_scene()
    geometry.configure_scene()
    root = geometry.build_vtol()
    orient_for_godot(root)
    geometry.save_outputs(root)
    if args.render_previews:
        geometry.render_previews(root)
    print(f"Blender version: {bpy.app.version_string}")
    print(f"Saved corrected Blender source: {geometry.SOURCE_BLEND}")
    print(f"Saved corrected Godot runtime GLB: {geometry.RUNTIME_GLB}")


if __name__ == "__main__":
    main()
