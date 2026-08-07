class_name VehicleAssetValidator
extends RefCounted

static func validate_metadata(manifest: Dictionary, audit: Dictionary) -> PackedStringArray:
    var errors := PackedStringArray()
    if manifest.is_empty():
        errors.append("source manifest is missing or empty")
        return errors
    if audit.is_empty():
        errors.append("runtime audit is missing or empty")
        return errors
    if String(manifest.get("asset_id", "")).is_empty():
        errors.append("asset_id must be present")
    if not bool(audit.get("deterministic_repeat_match", false)):
        errors.append("runtime generation must be deterministic across repeated runs")

    var budget: Dictionary = manifest.get("runtime_budget", {})
    var lods: Dictionary = audit.get("lods", {})
    var required_lods := int(budget.get("required_lod_count", 0))
    if required_lods <= 0:
        errors.append("runtime budget must define a positive required_lod_count")
    elif lods.size() < required_lods:
        errors.append("runtime audit contains fewer LODs than required")

    var lod0: Dictionary = lods.get("lod0", {})
    var lod0_triangles := int(lod0.get("triangles", 0))
    var lod0_min := int(budget.get("lod0_triangles_min", 0))
    var lod0_max := int(budget.get("lod0_triangles_max", 0))
    if lod0_triangles < lod0_min or lod0_triangles > lod0_max:
        errors.append("LOD0 triangles are outside the configured hero-car budget")

    _validate_fraction(errors, lods, "lod1", float(budget.get("lod1_max_fraction_of_lod0", 1.0)))
    _validate_fraction(errors, lods, "lod2", float(budget.get("lod2_max_fraction_of_lod0", 1.0)))
    _validate_fraction(errors, lods, "lod3", float(budget.get("lod3_max_fraction_of_lod0", 1.0)))

    var material_count := int(audit.get("runtime_material_count", 0))
    var material_min := int(budget.get("material_count_min", 0))
    var material_max := int(budget.get("material_count_max", 2147483647))
    if material_count < material_min or material_count > material_max:
        errors.append("runtime material count is outside the configured budget")

    var runtime_generation: Dictionary = manifest.get("runtime_generation", {})
    if bool(runtime_generation.get("embedded_texture_payload_required", false)):
        var payload: Dictionary = audit.get("texture_payload", {})
        var minimum_images := int(runtime_generation.get("minimum_embedded_images", 1))
        if int(payload.get("images", 0)) < minimum_images or int(payload.get("textures", 0)) < minimum_images:
            errors.append("required embedded texture payload is incomplete")

    var import_audit: Dictionary = audit.get("godot_4_7_1_import", {})
    if not bool(import_audit.get("verified", false)):
        errors.append("Godot runtime import has not been verified")
    if not bool(import_audit.get("all_semantic_nodes_present", false)):
        errors.append("runtime semantic-node audit is incomplete")

    var semantic_nodes: Array = audit.get("semantic_nodes", [])
    for required in ["body_exterior", "cockpit_static", "glass_static", "steering_wheel_visual", "wheel_fl_visual", "wheel_fr_visual", "wheel_rl_visual", "wheel_rr_visual"]:
        if required not in semantic_nodes:
            errors.append("missing required semantic node: %s" % required)

    var wheel_centers: Dictionary = audit.get("wheel_centers_blender", {})
    for id in ["fl", "fr", "rl", "rr"]:
        if not wheel_centers.has(id):
            errors.append("missing audited wheel center: %s" % id)
    return errors

static func release_errors(manifest: Dictionary) -> PackedStringArray:
    var errors := PackedStringArray()
    var license_status := String(manifest.get("license_status", "unknown"))
    if license_status not in ["verified_for_release", "release_safe", "verified"]:
        errors.append("release blocked: asset licensing is %s" % license_status)
    return errors

static func validate_scene_contract(vehicle: Node) -> PackedStringArray:
    var errors := PackedStringArray()
    if vehicle == null:
        errors.append("vehicle scene root is missing")
        return errors
    if not vehicle is RigidBody3D:
        errors.append("vehicle scene root must be RigidBody3D")
    var chassis := vehicle.get_node_or_null("ChassisCollision") as CollisionShape3D
    if chassis == null or chassis.get_parent() != vehicle or chassis.shape == null:
        errors.append("chassis collision must be a direct populated child of the vehicle body")
    for path in [
        "WheelAnchors/WheelFL", "WheelAnchors/WheelFR", "WheelAnchors/WheelRL", "WheelAnchors/WheelRR",
        "CameraAnchors/ChaseAnchor", "CameraAnchors/HoodAnchor", "CameraAnchors/BumperAnchor", "CameraAnchors/CockpitAnchor", "CameraAnchors/LookTarget",
        "EffectsAnchors/ExhaustAnchor", "EffectsAnchors/TireFL", "EffectsAnchors/TireFR", "EffectsAnchors/TireRL", "EffectsAnchors/TireRR",
        "VisualRoot/VehicleVisualRig", "AudioBridge", "EffectsBridge"
    ]:
        if vehicle.get_node_or_null(path) == null:
            errors.append("vehicle scene missing required production node: %s" % path)
    return errors

static func _validate_fraction(errors: PackedStringArray, lods: Dictionary, lod_name: String, maximum: float) -> void:
    var lod: Dictionary = lods.get(lod_name, {})
    if lod.is_empty():
        errors.append("missing runtime %s" % lod_name)
        return
    var fraction := float(lod.get("fraction_of_lod0", lod.get("ratio", 1.0)))
    if fraction > maximum:
        errors.append("%s exceeds configured LOD fraction budget" % lod_name)
