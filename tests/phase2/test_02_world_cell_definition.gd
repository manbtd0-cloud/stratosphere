extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var cell_script = load("res://src/world/grid/world_cell_definition.gd")
	if cell_script == null:
		fail("WorldCellDefinition script must exist")
		return
	var grid_script = load("res://src/world/grid/world_grid.gd")
	if grid_script == null:
		fail("WorldGrid script must load")
		return
	var grid = grid_script.new()
	var cell = cell_script.new()
	cell.coord = Vector2i(-3, 2)
	cell.id = grid.coord_to_id(cell.coord)
	cell.terrain_backend_key = &"builtin"
	cell.persistent_state_namespace = &"world.proving"
	cell.road_segment_ids.assign([&"road.alpha", &"road.alpha", &"road.beta"])
	cell.surface_region_ids.assign([&"surface.grass", &"surface.grass"])
	var errors: PackedStringArray = cell.validation_errors(grid)
	if not errors.is_empty():
		fail("valid cell rejected: %s" % errors)
		return
	if cell.road_segment_ids != [&"road.alpha", &"road.beta"]:
		fail("road IDs must be deduplicated while preserving order")
		return
	if cell.surface_region_ids != [&"surface.grass"]:
		fail("surface region IDs must be deduplicated")
		return
	cell.id = &"world.proving.cp00_p00"
	errors = cell.validation_errors(grid)
	if not _contains_fragment(errors, "id does not match"):
		fail("ID/coordinate mismatch must fail validation")
		return
	cell.id = grid.coord_to_id(cell.coord)
	cell.persistent_state_namespace = &""
	errors = cell.validation_errors(grid)
	if not _contains_fragment(errors, "persistent"):
		fail("persistent state namespace must be required")
		return
	cell.persistent_state_namespace = &"world.proving"
	cell.coord = Vector2i(6, 0)
	errors = cell.validation_errors(grid)
	if not _contains_fragment(errors, "outside world grid"):
		fail("out-of-bounds cell coordinates must fail validation")
		return
	print("PASS: phase2 02_world_cell_definition")
	quit(0)

func _contains_fragment(values: PackedStringArray, fragment: String) -> bool:
	for value in values:
		if fragment in value:
			return true
	return false
