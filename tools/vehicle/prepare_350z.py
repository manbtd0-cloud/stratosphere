#!/usr/bin/env python3
"""Deterministic Blender 5.2 runtime preparation for the Phase 1 350Z source."""
from __future__ import annotations

import argparse
import json
import os
import sys
import traceback
from collections import Counter
from pathlib import Path

LOD0_MIN, LOD0_MAX, MATERIAL_MAX = 150_000, 250_000, 14
LOD_RANGES = {"lod1": (0.45, 0.55), "lod2": (0.15, 0.25), "lod3": (0.05, 0.10)}
UTILITY_COLLECTIONS = {"Collection", "LightSetup"}
WHEEL_COLLECTIONS = {"jr11Wheels", "TireVol2", "Jr11Brake"}
COCKPIT_COLLECTIONS = {"InterDash", "Interier", "InterSeats", "InterDoor", "InterMidPanel"}
GLASS_MATERIALS = {"Window", "PolarizedWindow", "WindowPlastic"}
STEERING_PIVOT_FALLBACK = (-0.3869, -0.1646, -0.0151)

REPRESENTATIVE = {
    "runtime_paint": "Paint", "runtime_glass": "PolarizedWindow",
    "runtime_light_red": "BrakeLightGlassCover", "runtime_light_amber": "Blinker",
    "runtime_light_clear": "ReverseLightCover", "runtime_chrome": "ZChromeDetail",
    "runtime_rim": "Rim", "runtime_tire": "TireWithNormal",
    "runtime_brake_disc": "BrakeDisk", "runtime_caliper": "Caliper",
    "runtime_interior_plastic": "InterPlasticDashRough", "runtime_leather": "SeatsLeather",
    "runtime_carbon": "SteeringCarbon", "runtime_decal": "License",
}


def args_from_blender() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--source", type=Path, required=True)
    p.add_argument("--out-dir", type=Path, required=True)
    p.add_argument("--audit-json", type=Path)
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    return p.parse_args(argv)


def collections(obj) -> set[str]:
    return {c.name for c in obj.users_collection}


def triangles(mesh) -> int:
    return sum(max(0, len(poly.vertices) - 2) for poly in mesh.polygons)


def triangle_count(objects, depsgraph=None) -> int:
    total = 0
    for obj in objects:
        if obj.type != "MESH":
            continue
        if depsgraph is not None and obj.modifiers:
            evaluated = obj.evaluated_get(depsgraph)
            mesh = evaluated.to_mesh()
            total += triangles(mesh)
            evaluated.to_mesh_clear()
        else:
            total += triangles(obj.data)
    return total


def source_role(obj, steering_pivot) -> str:
    cols = collections(obj)
    if cols & WHEEL_COLLECTIONS:
        return "wheel"
    if "Steering" in cols:
        if (obj.matrix_world.translation - steering_pivot).length < 0.08 and max(obj.dimensions) < 0.65:
            return "steering"
        return "cockpit"
    if cols & COCKPIT_COLLECTIONS:
        return "cockpit"
    if "Windshield" in cols or "RearWindshield" in cols:
        return "glass"
    if any(slot.material and slot.material.name in GLASS_MATERIALS for slot in obj.material_slots):
        return "glass"
    return "exterior"


def steering_pivot(bpy):
    from mathutils import Vector
    points = []
    coll = bpy.data.collections.get("Steering")
    if coll:
        for obj in coll.objects:
            if obj.type == "MESH":
                t = obj.matrix_world.translation
                points.append((round(t.x, 3), round(t.y, 3), round(t.z, 3)))
    return Vector(Counter(points).most_common(1)[0][0] if points else STEERING_PIVOT_FALLBACK)


def material_family(name: str) -> str:
    if name == "Paint": return "runtime_paint"
    if "Window" in name: return "runtime_glass"
    if "BrakeLight" in name: return "runtime_light_red"
    if name == "Blinker": return "runtime_light_amber"
    if name in {"ReverseLightCover", "PolarizedLight", "RingLight"}: return "runtime_light_clear"
    if name in {"Rim", "JrLogo"}: return "runtime_rim"
    if "Tire" in name: return "runtime_tire"
    if "BrakeDisk" in name: return "runtime_brake_disc"
    if name == "Caliper": return "runtime_caliper"
    if name in {"SeatsLeather", "SteeringLeather", "SteeringMAterialSide"}: return "runtime_leather"
    if "Carbon" in name: return "runtime_carbon"
    if name in {"License", "Dots Stroke"}: return "runtime_decal"
    chrome_tokens = ("Chrome", "Mirror", "Exhaust", "Handle", "Wheelhub", "Rivet")
    if any(token in name for token in chrome_tokens): return "runtime_chrome"
    return "runtime_interior_plastic"


def runtime_materials(bpy):
    def principled(name, base, metallic, roughness, alpha=1.0, transmission=0.0, coat=0.0,
                   emission=None, emission_strength=0.0):
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        tree = mat.node_tree
        tree.nodes.clear()
        out = tree.nodes.new("ShaderNodeOutputMaterial")
        bsdf = tree.nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.inputs["Base Color"].default_value = base
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Alpha"].default_value = alpha
        bsdf.inputs["Transmission Weight"].default_value = transmission
        bsdf.inputs["Coat Weight"].default_value = coat
        if emission is not None:
            bsdf.inputs["Emission Color"].default_value = emission
            bsdf.inputs["Emission Strength"].default_value = emission_strength
        tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
        if alpha < 0.999:
            mat.surface_render_method = "BLENDED"
        return mat

    custom = {
        "runtime_glass": lambda: principled("runtime_glass", (0.012, 0.018, 0.025, 1), 0, 0.08, 0.28, 0.72, 0.1),
        "runtime_light_red": lambda: principled("runtime_light_red", (0.45, 0.004, 0.003, 1), 0, 0.1, 0.78, 0.15, 0.15, (0.8, 0.01, 0.005, 1), 0.25),
        "runtime_light_amber": lambda: principled("runtime_light_amber", (0.75, 0.18, 0.01, 1), 0, 0.1, 0.82, 0.12, 0.15, (1, 0.25, 0.01, 1), 0.18),
        "runtime_light_clear": lambda: principled("runtime_light_clear", (0.65, 0.7, 0.78, 1), 0, 0.08, 0.72, 0.2, 0.15, (0.45, 0.55, 0.7, 1), 0.08),
    }
    result = {}
    for family, representative in REPRESENTATIVE.items():
        if family in custom:
            material = custom[family]()
        else:
            source = bpy.data.materials.get(representative)
            if source is None:
                raise RuntimeError(f"Missing representative material: {representative}")
            material = source.copy()
            material.name = family
        result[family] = material
    if len(result) != MATERIAL_MAX:
        raise RuntimeError(f"Expected exactly {MATERIAL_MAX} runtime material families")
    return result


def remap_materials(obj, materials) -> None:
    old = list(obj.data.materials)
    mapped = [materials[material_family(mat.name if mat else "")] for mat in old]
    unique = []
    indices = {}
    for index, mat in enumerate(mapped):
        key = mat.name
        target = next((i for i, item in enumerate(unique) if item.name == key), None)
        if target is None:
            target = len(unique)
            unique.append(mat)
        indices[index] = target
    for poly in obj.data.polygons:
        poly.material_index = indices.get(poly.material_index, 0)
    obj.data.materials.clear()
    for mat in unique:
        obj.data.materials.append(mat)


def evaluated_copy(bpy, source, depsgraph, collection, role):
    evaluated = source.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
    obj = bpy.data.objects.new(f"runtime_{source.name}", mesh)
    collection.objects.link(obj)
    obj.matrix_world = source.matrix_world.copy()
    obj["runtime_role"] = role
    return obj


def bbox_center(obj):
    from mathutils import Vector
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return sum(points, Vector()) / len(points)


def wheel_centers(source_objects):
    centers = []
    for obj in source_objects:
        if "TireVol2" not in collections(obj):
            continue
        center = bbox_center(obj)
        if all((center - other).length > 0.05 for other in centers):
            centers.append(center)
    if len(centers) != 4:
        raise RuntimeError(f"Expected four tire centers, got {len(centers)}")
    result = {}
    for center in centers:
        result[("f" if center.y < 0 else "r") + ("l" if center.x < 0 else "r")] = center
    if set(result) != {"fl", "fr", "rl", "rr"}:
        raise RuntimeError(f"Unable to classify wheel centers: {result}")
    return result


def nearest_label(point, centers):
    return min(centers, key=lambda label: (point - centers[label]).length_squared)


def split_wheel_object(bpy, bmesh, obj, centers, collection):
    assignments = {nearest_label(obj.matrix_world @ poly.center, centers) for poly in obj.data.polygons}
    pieces = []
    for label in sorted(assignments):
        mesh = bpy.data.meshes.new(f"{obj.data.name}_{label}")
        for mat in obj.data.materials:
            mesh.materials.append(mat)
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        remove = [face for face in bm.faces if nearest_label(obj.matrix_world @ face.calc_center_median(), centers) != label]
        if remove:
            bmesh.ops.delete(bm, geom=remove, context="FACES")
        loose = [vertex for vertex in bm.verts if not vertex.link_faces and not vertex.link_edges]
        if loose:
            bmesh.ops.delete(bm, geom=loose, context="VERTS")
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()
        if not mesh.polygons:
            bpy.data.meshes.remove(mesh)
            continue
        piece = bpy.data.objects.new(f"{obj.name}_{label}", mesh)
        collection.objects.link(piece)
        piece.matrix_world = obj.matrix_world.copy()
        piece["runtime_role"] = "wheel"
        piece["wheel_label"] = label
        pieces.append(piece)
    bpy.data.objects.remove(obj, do_unlink=True)
    return pieces


def clone(bpy, obj, collection):
    copied = obj.copy()
    copied.data = obj.data.copy()
    collection.objects.link(copied)
    return copied


def apply_decimate(bpy, obj, ratio) -> None:
    if ratio >= 0.999:
        return
    modifier = obj.modifiers.new("runtime_decimate", "DECIMATE")
    modifier.ratio = max(0.01, min(1.0, ratio))
    modifier.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def make_lod(bpy, lod0, name, target_fraction, omit_groups):
    collection = bpy.data.collections.new(f"runtime_{name}")
    bpy.context.scene.collection.children.link(collection)
    source = [obj for obj in lod0 if obj.get("runtime_group", "body") not in omit_groups]
    base_total = triangle_count(lod0)
    target = base_total * target_fraction
    low, high, chosen = 0.02, 1.0, target_fraction
    for _ in range(10):
        ratio = (low + high) / 2
        temporary = []
        for obj in source:
            copied = clone(bpy, obj, collection)
            mod = copied.modifiers.new("probe", "DECIMATE")
            mod.ratio = ratio
            mod.use_collapse_triangulate = True
            temporary.append(copied)
        bpy.context.view_layer.update()
        total = triangle_count(temporary, bpy.context.evaluated_depsgraph_get())
        for obj in temporary:
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.context.view_layer.update()
        if total > target:
            high = ratio
        else:
            low = ratio
        chosen = ratio
    output = []
    for obj in source:
        copied = clone(bpy, obj, collection)
        apply_decimate(bpy, copied, chosen)
        output.append(copied)
    return output, chosen


def parent_preserve(obj, parent) -> None:
    world = obj.matrix_world.copy()
    obj.parent = parent
    obj.matrix_world = world


def hierarchy(bpy, objects, centers, steer_pivot):
    from mathutils import Vector
    collection = objects[0].users_collection[0]
    root = bpy.data.objects.new("prototype_rwd_coupe", None)
    collection.objects.link(root)
    empties = []

    def empty(name, position):
        obj = bpy.data.objects.new(name, None)
        collection.objects.link(obj)
        obj.matrix_world.translation = position
        parent_preserve(obj, root)
        empties.append(obj)
        return obj

    body = empty("body_exterior", Vector())
    cockpit = empty("cockpit_static", Vector())
    glass = empty("glass_static", Vector())
    steering = empty("steering_wheel_visual", steer_pivot)
    wheels = {label: empty(f"wheel_{label}_visual", center) for label, center in centers.items()}
    for obj in objects:
        group = obj.get("runtime_group", "body")
        parent = {"cockpit": cockpit, "glass": glass, "steering": steering}.get(group, body)
        if group == "wheel":
            parent = wheels[obj.get("wheel_label")]
        parent_preserve(obj, parent)
    return root, empties


def export_glb(bpy, objects, path, centers, steer_pivot) -> None:
    root, empties = hierarchy(bpy, objects, centers, steer_pivot)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [root, *empties, *objects]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=str(path.resolve()), export_format="GLB", use_selection=True,
                              export_apply=True, export_yup=True, export_materials="EXPORT",
                              export_cameras=False, export_lights=False)
    for obj in objects:
        world = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world
    for obj in reversed(empties):
        bpy.data.objects.remove(obj, do_unlink=True)


def used_materials(objects) -> set[str]:
    names = set()
    for obj in objects:
        slots = list(obj.data.materials)
        for poly in obj.data.polygons:
            if 0 <= poly.material_index < len(slots) and slots[poly.material_index]:
                names.add(slots[poly.material_index].name)
    return names


def main() -> int:
    args = args_from_blender()
    if args.source.name.lower() != "350z.blend":
        raise RuntimeError("Runtime authoring must start from 350z.blend; modifier source is reference-only")
    args.out_dir.mkdir(parents=True, exist_ok=True)
    import bpy, bmesh
    bpy.ops.wm.open_mainfile(filepath=str(args.source.resolve()))
    source = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and not obj.hide_render
              and not (collections(obj) & UTILITY_COLLECTIONS)]
    if not source:
        raise RuntimeError("No visible vehicle mesh objects")
    centers = wheel_centers(source)
    steer_pivot = steering_pivot(bpy)

    for obj in source:
        cols = collections(obj)
        for modifier in obj.modifiers:
            if modifier.type == "SUBSURF":
                modifier.levels = modifier.render_levels = 0
        if obj.name == "Plane" or "Steering" in cols or "InterDash" in cols or "LightsRedux" in cols:
            for modifier in obj.modifiers:
                if modifier.type == "SUBSURF":
                    modifier.levels = modifier.render_levels = 1
        if "TireVol2" in cols:
            modifier = obj.modifiers.new("runtime_tire_decimate", "DECIMATE")
            modifier.ratio = 0.55
            modifier.use_collapse_triangulate = True

    depsgraph = bpy.context.evaluated_depsgraph_get()
    materials = runtime_materials(bpy)
    work = bpy.data.collections.new("runtime_work")
    bpy.context.scene.collection.children.link(work)
    runtime = []
    for source_obj in source:
        role = source_role(source_obj, steer_pivot)
        obj = evaluated_copy(bpy, source_obj, depsgraph, work, role)
        remap_materials(obj, materials)
        runtime.append(obj)

    split = []
    for obj in list(runtime):
        if obj.get("runtime_role") == "wheel":
            runtime.remove(obj)
            split.extend(split_wheel_object(bpy, bmesh, obj, centers, work))
    runtime.extend(split)

    lod0 = []
    for obj in runtime:
        role = obj.get("runtime_role", "exterior")
        obj["runtime_group"] = {"cockpit": "cockpit", "glass": "glass", "steering": "steering", "wheel": "wheel"}.get(role, "body")
        lod0.append(obj)
    for label in ("fl", "fr", "rl", "rr"):
        if not any(obj.get("wheel_label", "") == label for obj in lod0):
            raise RuntimeError(f"Missing runtime wheel geometry: {label}")

    lod0_triangles = triangle_count(lod0)
    if not LOD0_MIN <= lod0_triangles <= LOD0_MAX:
        raise RuntimeError(f"LOD0 triangles {lod0_triangles:,} outside {LOD0_MIN:,}-{LOD0_MAX:,}")
    runtime_material_names = used_materials(lod0)
    if len(runtime_material_names) != MATERIAL_MAX:
        raise RuntimeError(f"Expected {MATERIAL_MAX} used runtime materials, got {len(runtime_material_names)}")

    results = {}
    lod0_path = args.out_dir / "prototype_rwd_coupe_lod0.glb"
    export_glb(bpy, lod0, lod0_path, centers, steer_pivot)
    results["lod0"] = {"triangles": lod0_triangles, "ratio": 1.0, "path": lod0_path.name}
    settings = {"lod1": (0.52, set()), "lod2": (0.20, {"cockpit", "steering"}), "lod3": (0.075, {"cockpit", "steering"})}
    for name, (target, omit) in settings.items():
        objects, ratio = make_lod(bpy, lod0, name, target, omit)
        count = triangle_count(objects)
        fraction = count / lod0_triangles
        low, high = LOD_RANGES[name]
        if not low <= fraction <= high:
            raise RuntimeError(f"{name} fraction {fraction:.3f} outside {low:.2f}-{high:.2f}")
        path = args.out_dir / f"prototype_rwd_coupe_{name}.glb"
        export_glb(bpy, objects, path, centers, steer_pivot)
        results[name] = {"triangles": count, "ratio": fraction, "decimate_ratio": ratio, "path": path.name}

    audit = {
        "blender_version": bpy.app.version_string,
        "source": str(args.source.resolve()),
        "runtime_materials": sorted(runtime_material_names),
        "material_count": len(runtime_material_names),
        "wheel_centers_blender": {key: [round(value, 6) for value in center] for key, center in centers.items()},
        "steering_pivot_blender": [round(value, 6) for value in steer_pivot],
        "lods": results,
        "axes": {"blender_forward": "-Y", "blender_up": "+Z", "runtime_forward": "-Z", "runtime_up": "+Y"},
        "source_role_counts": dict(Counter(source_role(obj, steer_pivot) for obj in source)),
    }
    audit_path = args.audit_json or args.out_dir / "prototype_rwd_coupe_audit.json"
    audit_path.write_text(json.dumps(audit, indent=2), encoding="utf-8")
    print("RUNTIME_AUDIT " + json.dumps(audit))
    return 0


if __name__ == "__main__":
    try:
        exit_code = main()
        print("PREPARE_350Z_SUCCESS")
        sys.stdout.flush()
        raise SystemExit(exit_code)
    except SystemExit:
        raise
    except Exception:
        traceback.print_exc()
        sys.stderr.flush()
        sys.stdout.flush()
        os._exit(1)
