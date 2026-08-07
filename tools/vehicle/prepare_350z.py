#!/usr/bin/env python3
"""Deterministic Blender-side preparation entrypoint for the Phase 1 350Z source.

Run with Blender, for example:
  blender --background --python tools/vehicle/prepare_350z.py -- \
    --source /path/to/350z.blend --out-dir /path/to/output

The source archive itself is never committed to the repository.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

LOD0_MIN = 150_000
LOD0_MAX = 250_000
LOD_RATIOS = {"lod1": 0.55, "lod2": 0.25, "lod3": 0.10}
MATERIAL_MIN = 8
MATERIAL_MAX = 14


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--audit-json", type=Path)
    return parser.parse_args(argv)


def blender_args() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []


def mesh_triangles(obj, depsgraph) -> int:
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    try:
        return sum(max(0, len(poly.vertices) - 2) for poly in mesh.polygons)
    finally:
        evaluated.to_mesh_clear()


def object_role(name: str) -> str:
    value = name.lower()
    if "wheel" in value or "rim" in value or "tire" in value or "tyre" in value:
        return "wheel"
    if "brake" in value or "caliper" in value or "disc" in value or "rotor" in value:
        return "brake"
    if "steer" in value:
        return "steering"
    if "glass" in value or "window" in value or "windshield" in value:
        return "glass"
    if "headlight" in value or "taillight" in value or "lamp" in value or "light" in value:
        return "light"
    if any(token in value for token in ("dashboard", "dash", "seat", "console", "interior", "carpet", "gauge")):
        return "cockpit"
    return "body"


def validate_source(source: Path) -> None:
    if source.name.lower() != "350z.blend":
        raise RuntimeError(
            "Runtime authoring must start from 350z.blend. "
            "350zModifiers.blend is bake/reference only."
        )


def prepare() -> int:
    args = parse_args(blender_args())
    validate_source(args.source)
    args.out_dir.mkdir(parents=True, exist_ok=True)

    try:
        import bpy  # type: ignore
    except ImportError as exc:
        raise RuntimeError("This script must be executed by Blender's Python runtime") from exc

    bpy.ops.wm.open_mainfile(filepath=str(args.source.resolve()))
    depsgraph = bpy.context.evaluated_depsgraph_get()
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and not obj.hide_render]
    if not meshes:
        raise RuntimeError("350Z source contains no visible mesh objects")

    roles: dict[str, list[str]] = {key: [] for key in ("wheel", "brake", "steering", "glass", "light", "cockpit", "body")}
    triangle_count = 0
    for obj in meshes:
        roles[object_role(obj.name)].append(obj.name)
        triangle_count += mesh_triangles(obj, depsgraph)

    if len(roles["wheel"]) < 4:
        raise RuntimeError("Source audit must identify at least four wheel/tire mesh objects")
    if not roles["steering"]:
        raise RuntimeError("Source audit must identify a steering-wheel object")
    if not roles["cockpit"]:
        raise RuntimeError("Source audit must identify cockpit mesh objects")

    materials = {slot.material.name for obj in meshes for slot in obj.material_slots if slot.material is not None}
    # Source material count is expected to be high. Runtime consolidation is a required gate,
    # not something this script silently fakes by destroying authored assignments.
    source_material_count = len(materials)

    # Apply object transforms to establish deterministic meter scale and clean export matrices.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

    # Create LOD collections from the evaluated working source. LOD0 preserves evaluated source
    # detail and lower LODs use deterministic decimation ratios. Material consolidation remains
    # a visual-authoring gate and therefore prevents final export while >14 materials remain.
    if triangle_count < LOD0_MIN or triangle_count > LOD0_MAX:
        raise RuntimeError(
            f"Evaluated LOD0 has {triangle_count:,} triangles; required {LOD0_MIN:,}-{LOD0_MAX:,}. "
            "Retopology/decimation of the working master is required before runtime export."
        )
    if source_material_count > MATERIAL_MAX:
        raise RuntimeError(
            f"Source has {source_material_count} materials; consolidate to {MATERIAL_MIN}-{MATERIAL_MAX} "
            "approved runtime material families before export."
        )
    if source_material_count < MATERIAL_MIN:
        raise RuntimeError(
            f"Source has only {source_material_count} materials; expected at least {MATERIAL_MIN} runtime families."
        )

    exports: dict[str, dict[str, int | float | str]] = {}
    for lod_name, ratio in {"lod0": 1.0, **LOD_RATIOS}.items():
        collection = bpy.data.collections.new(f"runtime_{lod_name}")
        bpy.context.scene.collection.children.link(collection)
        duplicates = []
        for source_obj in meshes:
            dup = source_obj.copy()
            dup.data = source_obj.data.copy()
            collection.objects.link(dup)
            duplicates.append(dup)
            if ratio < 1.0:
                modifier = dup.modifiers.new(name=f"runtime_{lod_name}_decimate", type="DECIMATE")
                modifier.ratio = ratio
        bpy.ops.object.select_all(action="DESELECT")
        for obj in duplicates:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = duplicates[0]
        output = args.out_dir / f"prototype_rwd_coupe_{lod_name}.glb"
        bpy.ops.export_scene.gltf(
            filepath=str(output.resolve()),
            export_format="GLB",
            use_selection=True,
            export_apply=True,
            export_yup=True,
        )
        exports[lod_name] = {
            "path": output.name,
            "target_fraction_of_lod0": ratio,
        }

    audit = {
        "source": str(args.source),
        "evaluated_lod0_triangles": triangle_count,
        "material_count": source_material_count,
        "roles": roles,
        "exports": exports,
        "axes": {"forward": "-Z", "up": "+Y"},
    }
    audit_path = args.audit_json or (args.out_dir / "prototype_rwd_coupe_audit.json")
    audit_path.write_text(json.dumps(audit, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(prepare())
