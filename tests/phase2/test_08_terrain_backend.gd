extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var adapter_script = load("res://src/world/terrain/terrain_backend_adapter.gd")
	var backend_script = load("res://src/world/terrain/builtin_terrain_backend.gd")
	if adapter_script == null or backend_script == null:
		fail("terrain backend scripts must exist")
		return
	var grid := WorldGrid.new()
	var cell := WorldCellDefinition.new()
	cell.coord = Vector2i(-2, 3)
	cell.id = grid.coord_to_id(cell.coord)
	cell.terrain_backend_key = &"builtin"
	cell.persistent_state_namespace = &"world.proving"
	var backend = backend_script.new()
	if backend.backend_id() != &"builtin_grid":
		fail("built-in terrain backend ID must be stable")
		return
	if backend.supports(&"plugin_required"):
		fail("built-in backend must not claim plugin dependency")
		return
	var node: Node3D = backend.create_cell(cell, grid)
	if node == null:
		fail("built-in backend must create a terrain cell")
		return
	if node.position.distance_to(grid.coord_to_center(cell.coord)) > 0.001:
		fail("terrain cell must be centered on grid coordinate")
		node.free()
		return
	if float(node.get_meta("cell_size_m", 0.0)) != 512.0:
		fail("terrain cell must publish 512 m size")
		node.free()
		return
	var collision := node.get_node_or_null("TerrainCollision") as StaticBody3D
	if collision == null or collision.get_node_or_null("CollisionShape3D") == null:
		fail("built-in terrain cell must contain collision")
		node.free()
		return
	if collision.get_meta("surface_id", &"") != &"grass":
		fail("default terrain collision must publish grass surface")
		node.free()
		return
	if node.get_node_or_null("TerrainMesh") == null:
		fail("built-in terrain cell must include a visual mesh")
		node.free()
		return
	backend.release_cell(node)
	if is_instance_valid(node):
		fail("release_cell must free detached terrain cell safely")
		return
	print("PASS: phase2 08_terrain_backend")
	quit(0)
