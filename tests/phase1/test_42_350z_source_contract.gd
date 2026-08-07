extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)

func _init() -> void:
	var manifest_path := "res://assets/source/vehicle/prototype_rwd_coupe/source_manifest.json"
	var script_path := "res://tools/vehicle/prepare_350z.py"
	if not FileAccess.file_exists(manifest_path) or not FileAccess.file_exists(script_path):
		fail("350Z manifest and preparation script must exist")
		return
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	var payload = JSON.parse_string(file.get_as_text()) if file != null else null
	if not payload is Dictionary:
		fail("350Z source manifest must parse as JSON object")
		return
	if payload.get("asset_id", "") != "vehicle.prototype_rwd_coupe":
		fail("350Z source manifest asset ID mismatch")
		return
	if payload.get("license_status", "") != "unverified_for_release":
		fail("release licensing must remain explicitly unverified")
		return
	var budget: Dictionary = payload.get("runtime_budget", {})
	if int(budget.get("lod0_triangles_min", 0)) != 150000 or int(budget.get("lod0_triangles_max", 0)) != 250000:
		fail("LOD0 budget must remain 150k-250k")
		return
	if int(budget.get("required_lod_count", 0)) != 4:
		fail("hero car requires four LODs")
		return
	var high: Dictionary = payload.get("high_detail_reference", {})
	if not str(high.get("role", "")).contains("never direct runtime export"):
		fail("high-detail source must be reference-only")
		return
	print("PASS: phase1 42_350z_source_contract")
	quit(0)
