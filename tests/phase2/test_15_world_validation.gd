extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var validator_script = load("res://src/world/validation/world_validator.gd")
	if validator_script == null:
		fail("WorldValidator script must exist")
		return
	var valid := ProvingRegionFactory.create()
	var errors: PackedStringArray = validator_script.validate(valid)
	if not errors.is_empty():
		fail("canonical proving region must validate: %s" % errors)
		return
	var duplicate := ProvingRegionFactory.create()
	duplicate.cells[1].id = duplicate.cells[0].id
	if not _contains(validator_script.validate(duplicate), "duplicate cell id"):
		fail("duplicate cell IDs must fail validation")
		return
	var outside := ProvingRegionFactory.create()
	outside.cells[0].coord = Vector2i(6, 0)
	if not _contains(validator_script.validate(outside), "outside world grid"):
		fail("out-of-bounds cells must fail validation")
		return
	var missing_road := ProvingRegionFactory.create()
	missing_road.cells[0].road_segment_ids.append(&"road.does_not_exist")
	if not _contains(validator_script.validate(missing_road), "road.does_not_exist"):
		fail("cell references to missing roads must fail validation")
		return
	var invalid_profile := ProvingRegionFactory.create()
	invalid_profile.road_network.segments()[0].profile_id = &"invalid_profile"
	if not _contains(validator_script.validate(invalid_profile), "unknown road profile"):
		fail("invalid road profiles must fail validation")
		return
	var invalid_surface := ProvingRegionFactory.create()
	invalid_surface.road_network.segments()[0].surface_id = &"lava"
	if not _contains(validator_script.validate(invalid_surface), "unsupported road surface"):
		fail("unsupported road surfaces must fail validation")
		return
	print("PASS: phase2 15_world_validation")
	quit(0)

func _contains(values: PackedStringArray, fragment: String) -> bool:
	for value in values:
		if fragment in value:
			return true
	return false
