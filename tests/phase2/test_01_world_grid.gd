extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var grid_script = load("res://src/world/grid/world_grid.gd")
	if grid_script == null:
		fail("WorldGrid script must exist")
		return
	var grid = grid_script.new()
	if grid.cell_size != 512.0:
		fail("default cell size must be 512 m")
		return
	if grid.world_to_coord(Vector3.ZERO) != Vector2i(0, 0):
		fail("origin must map to cell 0,0")
		return
	if grid.world_to_coord(Vector3(-0.001, 0.0, -0.001)) != Vector2i(-1, -1):
		fail("negative coordinates must use floor semantics")
		return
	if grid.world_to_coord(Vector3(-512.0, 0.0, 511.999)) != Vector2i(-1, 0):
		fail("exact negative cell boundary must map deterministically")
		return
	if not grid.is_valid_coord(Vector2i(-6, -6)) or not grid.is_valid_coord(Vector2i(5, 5)):
		fail("address-space edge cells must be valid")
		return
	if grid.is_valid_coord(Vector2i(-7, 0)) or grid.is_valid_coord(Vector2i(6, 0)):
		fail("coordinates outside -6 through +5 must reject")
		return
	if grid.world_to_coord(Vector3(-3072.0, 0.0, -3072.0)) != Vector2i(-6, -6):
		fail("negative address-space edge must map to -6,-6")
		return
	if grid.world_to_coord(Vector3(3071.999, 0.0, 3071.999)) != Vector2i(5, 5):
		fail("positive address-space interior edge must map to 5,5")
		return
	for coord in [Vector2i(-6, -6), Vector2i(-3, 2), Vector2i(0, 0), Vector2i(5, 5)]:
		var center: Vector3 = grid.coord_to_center(coord)
		if grid.world_to_coord(center) != coord:
			fail("cell center must round-trip for %s" % coord)
			return
	var expected_id := StringName("world.proving.c-03_p02")
	if grid.coord_to_id(Vector2i(-3, 2)) != expected_id:
		fail("stable signed cell ID format changed")
		return
	if grid.id_to_coord(expected_id) != Vector2i(-3, 2):
		fail("stable cell ID must parse back to its coordinate")
		return
	if grid.id_to_coord(&"world.proving.invalid") != grid.INVALID_COORD:
		fail("invalid IDs must return INVALID_COORD")
		return
	var corner_neighbors: Array[Vector2i] = grid.neighbors(Vector2i(-6, -6))
	if corner_neighbors.size() != 3:
		fail("corner neighbor query must clip to grid bounds")
		return
	if Vector2i(-6, -6) in corner_neighbors:
		fail("neighbor query must not include the source cell")
		return
	for coord in corner_neighbors:
		if not grid.is_valid_coord(coord):
			fail("neighbor query returned an invalid coordinate")
			return
	print("PASS: phase2 01_world_grid")
	quit(0)
