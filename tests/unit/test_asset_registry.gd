extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func make_valid_record(record_script: Script):
	var record = record_script.new()
	record.id = &"environment.phase0_test_scene"
	record.kind = &"environment"
	record.source = "generated:phase0"
	record.license_status = &"internal"
	record.runtime_path = "res://src/bootstrap/main.tscn"
	record.scale_meters = 1.0
	record.triangle_count = 1000
	record.material_count = 2
	record.max_texture_resolution = 2048
	record.collision_status = &"ready"
	record.lod_count = 3
	record.shadow_mesh_ready = true
	record.runtime_status = &"approved"
	return record


func _init() -> void:
	var record_script := load("res://src/assets/asset_record.gd")
	var registry_script := load("res://src/assets/asset_registry.gd")
	if record_script == null or registry_script == null:
		fail("asset scripts must load")
		return

	var registry = registry_script.new()
	var valid = make_valid_record(record_script)
	if not registry.validate_record(valid).is_empty():
		fail("valid environment record must have no issues")
		return
	if registry.register(valid) != OK:
		fail("valid record must register")
		return
	if registry.register(valid) != ERR_ALREADY_EXISTS:
		fail("duplicate asset IDs must be rejected")
		return
	if registry.get_record(valid.id) == null:
		fail("registered record must be retrievable")
		return

	var missing_path = make_valid_record(record_script)
	missing_path.id = &"environment.missing"
	missing_path.runtime_path = "res://does/not/exist.glb"
	if registry.validate_record(missing_path).is_empty():
		fail("nonexistent runtime path must be reported")
		return

	var hero = make_valid_record(record_script)
	hero.id = &"vehicle.hero_over_budget"
	hero.kind = &"vehicle_hero"
	hero.lod_count = 1
	hero.material_count = 20
	hero.cockpit_suitability = &"full"
	var hero_issues: PackedStringArray = registry.validate_record(hero)
	if hero_issues.size() < 2:
		fail("hero vehicle must report missing LODs and material budget")
		return
	hero.lod_count = 4
	hero.budget_exception_reason = "temporary downloaded model pending consolidation"
	if not registry.validate_record(hero).is_empty():
		fail("documented budget exception with full LOD chain must validate")
		return

	var audit_path := "user://phase0-tests/assets-audit.json"
	if registry.export_audit(audit_path) != OK:
		fail("asset audit must export")
		return
	if not FileAccess.file_exists(audit_path):
		fail("asset audit file must exist")
		return

	registry.free()
	valid = null
	missing_path = null
	hero = null
	record_script = null
	registry_script = null
	print("PASS: asset registry contract")
	quit(0)
