extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var manager_script = load("res://src/world/streaming/world_stream_manager.gd")
	if manager_script == null:
		fail("WorldStreamManager script must exist")
		return
	var grid := WorldGrid.new()
	var backend := BuiltinTerrainBackend.new()
	var config := WorldStreamingConfig.new()
	var definitions: Array[WorldCellDefinition] = []
	for z in range(-6, 6):
		for x in range(-6, 6):
			var cell := WorldCellDefinition.new()
			cell.coord = Vector2i(x, z)
			cell.id = grid.coord_to_id(cell.coord)
			cell.terrain_backend_key = &"builtin"
			cell.persistent_state_namespace = &"world.proving"
			definitions.append(cell)
	var manager = manager_script.new()
	var errors: PackedStringArray = manager.configure(grid, backend, definitions, config)
	if not errors.is_empty():
		fail("valid streaming configuration rejected: %s" % errors)
		manager.free()
		return
	manager.update_observer(Vector3(10, 0, 10), Vector3.ZERO)
	var first_ids: PackedStringArray = manager.loaded_cell_ids()
	if first_ids.size() != 49:
		fail("center observer must instantiate the 7x7 visual set exactly")
		manager.free()
		return
	if _has_duplicates(first_ids) or manager.get_child_count() != first_ids.size():
		fail("manager must not create duplicate runtime cells")
		manager.free()
		return
	var old_edge_id := grid.coord_to_id(Vector2i(-3, 0))
	manager.update_observer(Vector3(600, 0, 10), Vector3(80, 0, 0))
	if old_edge_id not in manager.loaded_cell_ids():
		fail("one-cell unload hysteresis should retain recent boundary cell")
		manager.free()
		return
	manager.update_observer(Vector3(1300, 0, 10), Vector3(80, 0, 0))
	if old_edge_id in manager.loaded_cell_ids():
		fail("obsolete cell beyond hysteresis band must unload")
		manager.free()
		return
	for i in range(12):
		var position := Vector3(10, 0, 10) if i % 2 == 0 else Vector3(1300, 0, 10)
		var velocity := Vector3.ZERO if i % 2 == 0 else Vector3(80, 0, 0)
		manager.update_observer(position, velocity)
		var ids: PackedStringArray = manager.loaded_cell_ids()
		if _has_duplicates(ids) or manager.get_child_count() != ids.size():
			fail("repeated traversal created duplicate or stale cell ownership")
			manager.free()
			return
	manager.update_observer(Vector3(10, 0, 10), Vector3.ZERO)
	if manager.loaded_cell_ids().size() > 65:
		fail("return traversal retained an unbounded number of cells")
		manager.free()
		return
	manager.free()
	print("PASS: phase2 10_stream_manager")
	quit(0)

func _has_duplicates(values: PackedStringArray) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value):
			return true
		seen[value] = true
	return false
