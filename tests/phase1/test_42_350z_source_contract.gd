extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)

func _init() -> void:
	var manifest_path := "res://assets/source/vehicle/prototype_rwd_coupe/source_manifest.json"
	var audit_path := "res://assets/source/vehicle/prototype_rwd_coupe/runtime_audit.json"
	var script_path := "res://tools/vehicle/prepare_350z.py"
	for path in [manifest_path, audit_path, script_path]:
		if not FileAccess.file_exists(path):
			fail("missing 350Z pipeline file: %s" % path)
			return

	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	var manifest = JSON.parse_string(manifest_file.get_as_text()) if manifest_file != null else null
	if not manifest is Dictionary:
		fail("350Z source manifest must parse as JSON object")
		return
	if manifest.get("asset_id", "") != "vehicle.prototype_rwd_coupe":
		fail("350Z source manifest asset ID mismatch")
		return
	if manifest.get("license_status", "") != "unverified_for_release":
		fail("release licensing must remain explicitly unverified")
		return
	var budget: Dictionary = manifest.get("runtime_budget", {})
	if int(budget.get("lod0_triangles_min", 0)) != 150000 or int(budget.get("lod0_triangles_max", 0)) != 250000:
		fail("LOD0 budget must remain 150k-250k")
		return
	if int(budget.get("required_lod_count", 0)) != 4:
		fail("hero car requires four LODs")
		return
	var high: Dictionary = manifest.get("high_detail_reference", {})
	if not str(high.get("role", "")).contains("never direct runtime export"):
		fail("high-detail source must be reference-only")
		return

	var audit_file := FileAccess.open(audit_path, FileAccess.READ)
	var audit = JSON.parse_string(audit_file.get_as_text()) if audit_file != null else null
	if not audit is Dictionary:
		fail("350Z runtime audit must parse as JSON object")
		return
	if not bool(audit.get("deterministic_repeat_match", false)):
		fail("350Z runtime generation must be deterministic across repeated Blender runs")
		return
	if int(audit.get("runtime_material_count", 0)) != 14:
		fail("350Z runtime material family count must equal 14")
		return
	var lods: Dictionary = audit.get("lods", {})
	if int((lods.get("lod0", {}) as Dictionary).get("triangles", 0)) < 150000 or int((lods.get("lod0", {}) as Dictionary).get("triangles", 0)) > 250000:
		fail("generated LOD0 must stay inside hero-car triangle budget")
		return
	if float((lods.get("lod1", {}) as Dictionary).get("fraction_of_lod0", 1.0)) > 0.55:
		fail("generated LOD1 must stay at or below 55% of LOD0")
		return
	if float((lods.get("lod2", {}) as Dictionary).get("fraction_of_lod0", 1.0)) > 0.25:
		fail("generated LOD2 must stay at or below 25% of LOD0")
		return
	if float((lods.get("lod3", {}) as Dictionary).get("fraction_of_lod0", 1.0)) > 0.10:
		fail("generated LOD3 must stay at or below 10% of LOD0")
		return
	var godot_import: Dictionary = audit.get("godot_4_7_1_import", {})
	if not bool(godot_import.get("verified", false)) or not bool(godot_import.get("all_semantic_nodes_present", false)):
		fail("Godot 4.7.1 runtime import audit must remain verified")
		return

	var script_file := FileAccess.open(script_path, FileAccess.READ)
	var script_text := script_file.get_as_text() if script_file != null else ""
	for marker in ["PREPARE_350Z_SUCCESS", "runtime_glass", "wheel_{label}_visual", "steering_wheel_visual", "body_exterior"]:
		if not script_text.contains(marker):
			fail("350Z generator missing deterministic pipeline marker: %s" % marker)
			return
	print("PASS: phase1 42_350z_source_contract")
	quit(0)
