#!/usr/bin/env python3
"""Textured automotive-material overlay for the deterministic Phase 1 350Z geometry pipeline."""
from __future__ import annotations

import importlib.util
import json
import struct
import sys
from pathlib import Path


def _load_geometry_pipeline():
    path = Path(__file__).with_name("prepare_350z.py")
    spec = importlib.util.spec_from_file_location("phase1_350z_geometry", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load base 350Z pipeline: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def runtime_materials(bpy):
    source_root = Path(bpy.data.filepath).parent

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
        if coat > 0.0:
            bsdf.inputs["Coat Roughness"].default_value = min(0.12, roughness * 0.35)
        if emission is not None:
            bsdf.inputs["Emission Color"].default_value = emission
            bsdf.inputs["Emission Strength"].default_value = emission_strength
        tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
        if alpha < 0.999:
            mat.surface_render_method = "BLENDED"
        return mat

    def bsdf_node(mat):
        return next(node for node in mat.node_tree.nodes if node.type == "BSDF_PRINCIPLED")

    def image_texture(mat, relative_path, non_color=False):
        path = source_root / relative_path
        if not path.exists():
            raise RuntimeError(f"Missing required runtime texture source: {path}")
        image = bpy.data.images.load(str(path.resolve()), check_existing=True)
        if non_color:
            image.colorspace_settings.name = "Non-Color"
        node = mat.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = image
        node.interpolation = "Linear"
        return node

    def normal_texture(mat, relative_path, strength):
        tex = image_texture(mat, relative_path, non_color=True)
        normal = mat.node_tree.nodes.new("ShaderNodeNormalMap")
        normal.inputs["Strength"].default_value = strength
        mat.node_tree.links.new(tex.outputs["Color"], normal.inputs["Color"])
        mat.node_tree.links.new(normal.outputs["Normal"], bsdf_node(mat).inputs["Normal"])

    result = {
        "runtime_paint": principled("runtime_paint", (0.055, 0.075, 0.11, 1), 0.18, 0.20, coat=1.0),
        "runtime_glass": principled("runtime_glass", (0.012, 0.018, 0.025, 1), 0.0, 0.045, 0.22, 0.78, 0.18),
        "runtime_light_red": principled("runtime_light_red", (0.45, 0.004, 0.003, 1), 0.0, 0.08, 0.78, 0.18, 0.12, (0.8, 0.01, 0.005, 1), 0.25),
        "runtime_light_amber": principled("runtime_light_amber", (0.75, 0.18, 0.01, 1), 0.0, 0.08, 0.82, 0.16, 0.12, (1.0, 0.25, 0.01, 1), 0.18),
        "runtime_light_clear": principled("runtime_light_clear", (0.65, 0.70, 0.78, 1), 0.0, 0.05, 0.72, 0.24, 0.12, (0.45, 0.55, 0.70, 1), 0.08),
        "runtime_tire": principled("runtime_tire", (0.006, 0.007, 0.008, 1), 0.0, 0.88),
        "runtime_rim": principled("runtime_rim", (0.12, 0.13, 0.15, 1), 0.92, 0.20, coat=0.22),
        "runtime_brake_disc": principled("runtime_brake_disc", (0.17, 0.18, 0.19, 1), 0.92, 0.34),
        "runtime_caliper": principled("runtime_caliper", (0.72, 0.035, 0.015, 1), 0.30, 0.25, coat=0.35),
        "runtime_chrome": principled("runtime_chrome", (0.82, 0.84, 0.86, 1), 1.0, 0.075),
        "runtime_interior_plastic": principled("runtime_interior_plastic", (0.018, 0.019, 0.022, 1), 0.0, 0.66),
        "runtime_leather": principled("runtime_leather", (0.028, 0.022, 0.020, 1), 0.0, 0.46),
        "runtime_carbon": principled("runtime_carbon", (0.008, 0.009, 0.011, 1), 0.12, 0.25, coat=0.35),
        "runtime_decal": principled("runtime_decal", (1.0, 1.0, 1.0, 1), 0.0, 0.38, coat=0.18),
    }
    normal_texture(result["runtime_tire"], "Normalmaps/NormalMaptiree.png", 0.55)
    normal_texture(result["runtime_carbon"], "Normalmaps/NormalMapCarbon.png", 0.35)
    plate = image_texture(result["runtime_decal"], "japanese-plate-350z_zpsc8gt2dia.jpg")
    result["runtime_decal"].node_tree.links.new(plate.outputs["Color"], bsdf_node(result["runtime_decal"]).inputs["Base Color"])
    normal_texture(result["runtime_decal"], "License.png", 0.45)
    if len(result) != 14:
        raise RuntimeError("Expected exactly 14 runtime material families")
    return result


def glb_material_payload(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20 or data[:4] != b"glTF":
        raise RuntimeError(f"Invalid GLB: {path}")
    total = struct.unpack_from("<I", data, 8)[0]
    offset = 12
    payload = None
    while offset < total:
        length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset:offset + length]
        offset += length
        if chunk_type == 0x4E4F534A:
            payload = json.loads(chunk.rstrip(b"\x00 "))
            break
    if payload is None:
        raise RuntimeError(f"GLB JSON chunk missing: {path}")
    materials = {mat.get("name", ""): mat for mat in payload.get("materials", [])}
    for family in ("runtime_tire", "runtime_carbon"):
        if "normalTexture" not in materials.get(family, {}):
            raise RuntimeError(f"{family} must export an embedded normal texture")
    decal = materials.get("runtime_decal", {})
    if "normalTexture" not in decal or "baseColorTexture" not in decal.get("pbrMetallicRoughness", {}):
        raise RuntimeError("runtime_decal must export plate base-color and normal textures")
    images = len(payload.get("images", []))
    textures = len(payload.get("textures", []))
    if images < 4 or textures < 4:
        raise RuntimeError(f"Expected at least four embedded images/textures, got {images}/{textures}")
    return {"images": images, "textures": textures, "materials": {"runtime_tire": True, "runtime_carbon": True, "runtime_decal": True}}


def main() -> int:
    geometry = _load_geometry_pipeline()
    geometry.runtime_materials = runtime_materials
    args = geometry.args_from_blender()
    exit_code = geometry.main()
    if exit_code:
        return exit_code
    payload = glb_material_payload(args.out_dir / "prototype_rwd_coupe_lod0.glb")
    audit_path = args.audit_json or args.out_dir / "prototype_rwd_coupe_audit.json"
    audit = json.loads(audit_path.read_text(encoding="utf-8"))
    audit["texture_payload"] = payload
    audit_path.write_text(json.dumps(audit, indent=2), encoding="utf-8")
    print("PREPARE_350Z_TEXTURES_SUCCESS")
    return 0


if __name__ == "__main__":
    result = main()
    if result:
        raise SystemExit(result)
