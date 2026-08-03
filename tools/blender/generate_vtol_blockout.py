#!/usr/bin/env python3
"""Generate the original STRATOSPHERE VTOL blockout in Blender.

Run from the repository root:

    blender --background --python tools/blender/generate_vtol_blockout.py

Optional inspection renders:

    blender --background --python tools/blender/generate_vtol_blockout.py -- --render-previews
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path
from typing import Iterable

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
SOURCE_BLEND = ROOT / "assets" / "source" / "vtol_blockout.blend"
RUNTIME_GLB = ROOT / "assets" / "generated" / "vtol_blockout.glb"
PREVIEW_DIR = ROOT / "assets" / "generated" / "previews" / "vtol_blockout"

BODY_COLOR = (0.055, 0.075, 0.095, 1.0)
PANEL_COLOR = (0.12, 0.16, 0.19, 1.0)
ACCENT_COLOR = (0.82, 0.22, 0.055, 1.0)
GLASS_COLOR = (0.025, 0.11, 0.16, 1.0)
EMISSIVE_COLOR = (0.04, 0.55, 0.9, 1.0)


def parse_args() -> argparse.Namespace:
    argv = sys.argv
    user_args = argv[argv.index("--") + 1 :] if "--" in argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--render-previews", action="store_true")
    return parser.parse_args(user_args)


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for datablock in list(collection):
            if datablock.users == 0:
                collection.remove(datablock)


def configure_scene() -> None:
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world.color = (0.008, 0.012, 0.018)


def make_material(
    name: str,
    base_color: tuple[float, float, float, float],
    metallic: float,
    roughness: float,
    emission: tuple[float, float, float, float] | None = None,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.diffuse_color = base_color
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = base_color
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if emission is not None:
        emission_input = principled.inputs.get("Emission Color") or principled.inputs.get("Emission")
        if emission_input is not None:
            emission_input.default_value = emission
        strength_input = principled.inputs.get("Emission Strength")
        if strength_input is not None:
            strength_input.default_value = 4.0
    return material


def add_beveled_box(
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    material: bpy.types.Material,
    bevel: float = 0.18,
    parent: bpy.types.Object | None = None,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel_modifier = obj.modifiers.new("EdgeSoftening", "BEVEL")
    bevel_modifier.width = bevel
    bevel_modifier.segments = 3
    bevel_modifier.limit_method = "ANGLE"
    obj.data.materials.append(material)
    obj.parent = parent
    return obj


def add_wedge(
    name: str,
    vertices: Iterable[tuple[float, float, float]],
    faces: Iterable[tuple[int, ...]],
    material: bpy.types.Material,
    parent: bpy.types.Object,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(list(vertices), [], list(faces))
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    obj.parent = parent
    bevel_modifier = obj.modifiers.new("EdgeSoftening", "BEVEL")
    bevel_modifier.width = 0.12
    bevel_modifier.segments = 3
    bevel_modifier.limit_method = "ANGLE"
    return obj


def add_empty(
    name: str,
    location: tuple[float, float, float],
    parent: bpy.types.Object,
) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = 0.45
    obj.location = location
    obj.parent = parent
    return obj


def build_vtol() -> bpy.types.Object:
    body_material = make_material("BodyMaterial", BODY_COLOR, 0.72, 0.28)
    panel_material = make_material("PanelMaterial", PANEL_COLOR, 0.55, 0.38)
    accent_material = make_material("AccentMaterial", ACCENT_COLOR, 0.48, 0.24)
    glass_material = make_material("CockpitGlass", GLASS_COLOR, 0.18, 0.12)
    emissive_material = make_material(
        "EngineEmission",
        EMISSIVE_COLOR,
        0.2,
        0.18,
        emission=EMISSIVE_COLOR,
    )

    root = bpy.data.objects.new("VTOL_Blockout", None)
    bpy.context.collection.objects.link(root)
    root.empty_display_type = "PLAIN_AXES"
    root.empty_display_size = 0.8

    add_beveled_box(
        "Body",
        (0.0, 0.1, 0.25),
        (3.65, 6.25, 1.25),
        body_material,
        bevel=0.32,
        parent=root,
    )
    add_beveled_box(
        "UpperSpine",
        (0.0, 0.55, 0.92),
        (2.1, 3.6, 0.42),
        panel_material,
        bevel=0.16,
        parent=root,
    )
    add_beveled_box(
        "WingCore",
        (0.0, 0.45, 0.08),
        (8.85, 2.55, 0.24),
        body_material,
        bevel=0.13,
        parent=root,
    )

    cockpit_vertices = [
        (-1.18, -2.95, 0.55),
        (1.18, -2.95, 0.55),
        (-1.32, -1.15, 0.55),
        (1.32, -1.15, 0.55),
        (-0.82, -2.55, 1.52),
        (0.82, -2.55, 1.52),
        (-0.98, -1.18, 1.35),
        (0.98, -1.18, 1.35),
    ]
    cockpit_faces = [
        (0, 1, 3, 2),
        (4, 6, 7, 5),
        (0, 4, 5, 1),
        (2, 3, 7, 6),
        (0, 2, 6, 4),
        (1, 5, 7, 3),
    ]
    add_wedge("CockpitShell", cockpit_vertices, cockpit_faces, glass_material, root)

    for side, x_position in (("Left", -3.55), ("Right", 3.55)):
        pod = add_beveled_box(
            f"{side}EnginePod",
            (x_position, 0.35, 0.05),
            (1.35, 3.45, 1.15),
            accent_material,
            bevel=0.23,
            parent=root,
        )
        add_beveled_box(
            f"{side}Intake",
            (x_position, -1.47, 0.05),
            (1.02, 0.16, 0.78),
            panel_material,
            bevel=0.07,
            parent=root,
        )
        add_beveled_box(
            f"{side}Exhaust",
            (x_position, 2.15, 0.05),
            (0.9, 0.12, 0.62),
            emissive_material,
            bevel=0.04,
            parent=root,
        )
        pod["flight_role"] = "vector_engine"

    add_beveled_box(
        "TailBoom",
        (0.0, 2.55, 0.42),
        (1.45, 1.2, 0.68),
        panel_material,
        bevel=0.16,
        parent=root,
    )
    add_beveled_box(
        "TailPlane",
        (0.0, 2.95, 0.68),
        (4.15, 0.82, 0.18),
        body_material,
        bevel=0.08,
        parent=root,
    )

    add_empty("CockpitAnchor", (0.0, -1.85, 1.22), root)
    add_empty("ChaseAnchor", (0.0, 8.7, 3.4), root)
    add_empty("ForwardMarker", (0.0, -5.0, 0.25), root)

    root["forward_axis_after_gltf_export"] = "-Z"
    root["up_axis_after_gltf_export"] = "+Y"
    root["unit_scale_meters"] = 1.0
    return root


def select_hierarchy(root: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for child in root.children_recursive:
        child.select_set(True)
    bpy.context.view_layer.objects.active = root


def save_outputs(root: bpy.types.Object) -> None:
    SOURCE_BLEND.parent.mkdir(parents=True, exist_ok=True)
    RUNTIME_GLB.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_BLEND))
    select_hierarchy(root)
    bpy.ops.export_scene.gltf(
        filepath=str(RUNTIME_GLB),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_extras=True,
    )


def point_camera_at(camera: bpy.types.Object, target: Vector) -> None:
    direction = target - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_previews(root: bpy.types.Object) -> None:
    del root
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene

    key_data = bpy.data.lights.new("KeyLight", type="AREA")
    key_data.energy = 1200.0
    key_data.shape = "DISK"
    key_data.size = 8.0
    key = bpy.data.objects.new("KeyLight", key_data)
    bpy.context.collection.objects.link(key)
    key.location = (7.0, -8.0, 10.0)

    fill_data = bpy.data.lights.new("FillLight", type="AREA")
    fill_data.energy = 650.0
    fill_data.size = 10.0
    fill = bpy.data.objects.new("FillLight", fill_data)
    bpy.context.collection.objects.link(fill)
    fill.location = (-8.0, 5.0, 6.0)

    camera_data = bpy.data.cameras.new("InspectionCamera")
    camera_data.lens = 56.0
    camera = bpy.data.objects.new("InspectionCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera

    views = {
        "front": (0.0, -15.0, 3.0),
        "rear": (0.0, 15.0, 3.0),
        "left": (-15.0, 0.0, 3.0),
        "right": (15.0, 0.0, 3.0),
        "top": (0.0, 0.0, 18.0),
        "cockpit": (4.5, -8.0, 4.0),
    }
    for view_name, location in views.items():
        camera.location = location
        point_camera_at(camera, Vector((0.0, 0.0, 0.35)))
        scene.render.filepath = str(PREVIEW_DIR / f"{view_name}.png")
        bpy.ops.render.render(write_still=True)


def main() -> None:
    args = parse_args()
    reset_scene()
    configure_scene()
    root = build_vtol()
    save_outputs(root)
    if args.render_previews:
        render_previews(root)
    print(f"Saved Blender source: {SOURCE_BLEND}")
    print(f"Saved Godot runtime GLB: {RUNTIME_GLB}")


if __name__ == "__main__":
    main()