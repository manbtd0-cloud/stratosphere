extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)

func _init() -> void:
	var manifest_path := "res://assets/source/vehicle/prototype_rwd_coupe/source_manifest.json"
	var audit_path := "res://assets/source/vehicle/prototype_rwd_coupe/runtime_audit.json"
	var script_path := "res://tools/vehicle/prepare_350z.py"
	var texture_script_path := "res://tools/vehicle/prepare_350z_textured.py"
	for path in [manifest_path, audit_path, script_path, texture_script_path]:
		if not FileAccess.file_exists(path): fail("missing 350Z pipeline file: %s" % path); return
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var audit = JSON.parse_string(FileAccess.get_file_as_string(audit_path))
	if not manifest is Dictionary or not audit is Dictionary: fail("350Z metadata must parse"); return
	if manifest.get("asset_id", "") != "vehicle.prototype_rwd_coupe": fail("asset ID mismatch"); return
	if manifest.get("license_status", "") != "unverified_for_release": fail("release licensing must remain explicitly unverified"); return
	var budget: Dictionary = manifest.get("runtime_budget", {})
	if int(budget.get("lod0_triangles_min",0)) != 150000 or int(budget.get("lod0_triangles_max",0)) != 250000: fail("LOD0 budget changed"); return
	if int(budget.get("required_lod_count",0)) != 4: fail("hero car requires four LODs"); return
	var high: Dictionary = manifest.get("high_detail_reference", {})
	if not str(high.get("role", "")).contains("never direct runtime export"): fail("high detail source policy changed"); return
	if not bool(audit.get("deterministic_repeat_match", false)): fail("generation must be deterministic"); return
	if int(audit.get("runtime_material_count", 0)) != 14: fail("runtime material family count must equal 14"); return
	var lods: Dictionary = audit.get("lods", {})
	if int((lods.get("lod0", {}) as Dictionary).get("triangles", 0)) < 150000 or int((lods.get("lod0", {}) as Dictionary).get("triangles", 0)) > 250000: fail("LOD0 triangle budget"); return
	if float((lods.get("lod1", {}) as Dictionary).get("fraction_of_lod0", 1.0)) > 0.55: fail("LOD1 budget"); return
	if float((lods.get("lod2", {}) as Dictionary).get("fraction_of_lod0", 1.0)) > 0.25: fail("LOD2 budget"); return
	if float((lods.get("lod3", {}) as Dictionary).get("fraction_of_lod0", 1.0)) > 0.10: fail("LOD3 budget"); return
	var toolchain: Dictionary = manifest.get("toolchain", {})
	if str(toolchain.get("geometry_generator_sha256", "")) == "" or str(toolchain.get("material_entrypoint_sha256", "")) != str(audit.get("generator_sha256", "")): fail("manifest and audit pipeline fingerprints must match"); return
	var payload: Dictionary = audit.get("texture_payload", {})
	if int(payload.get("images", 0)) < 4 or int(payload.get("textures", 0)) < 4: fail("runtime car must embed at least four images/textures"); return
	var textured: Dictionary = payload.get("materials", {})
	for material in ["runtime_tire", "runtime_carbon", "runtime_decal"]:
		if not bool(textured.get(material, false)): fail("missing required textured material: %s" % material); return
	var godot_import: Dictionary = audit.get("godot_4_7_1_import", {})
	if not bool(godot_import.get("verified", false)) or not bool(godot_import.get("all_semantic_nodes_present", false)): fail("Godot runtime import must remain verified"); return
	var script_text := FileAccess.get_file_as_string(script_path)
	for marker in ["PREPARE_350Z_SUCCESS", "wheel_{label}_visual", "steering_wheel_visual", "body_exterior"]:
		if not script_text.contains(marker): fail("geometry generator missing marker: %s" % marker); return
	var texture_script_text := FileAccess.get_file_as_string(texture_script_path)
	for marker in ["PREPARE_350Z_TEXTURES_SUCCESS", "glb_material_payload", "runtime_tire", "runtime_carbon", "runtime_decal", "NormalMaptiree.png", "NormalMapCarbon.png"]:
		if not texture_script_text.contains(marker): fail("material entrypoint missing marker: %s" % marker); return
	print("PASS: phase1 42_350z_source_contract")
	quit(0)
