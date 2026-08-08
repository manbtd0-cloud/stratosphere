class_name BuiltinTerrainBackend
extends TerrainBackendAdapter

func backend_id() -> StringName:
	return &"builtin_grid"

func supports(feature: StringName) -> bool:
	return feature in [&"cell_visual", &"cell_collision", &"surface_metadata", &"height_interface"]

func create_cell(cell: WorldCellDefinition, grid: WorldGrid) -> Node3D:
	if cell == null or grid == null or not cell.validation_errors(grid).is_empty():
		return null
	var root := Node3D.new()
	root.name = "TerrainCell_%s" % String(cell.id).replace(".", "_").replace("-", "n")
	root.position = grid.coord_to_center(cell.coord)
	root.set_meta("cell_id", cell.id)
	root.set_meta("cell_coord", cell.coord)
	root.set_meta("cell_size_m", grid.cell_size)
	root.set_meta("terrain_backend", backend_id())

	var plane := PlaneMesh.new()
	plane.size = Vector2(grid.cell_size, grid.cell_size)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.19, 0.28, 0.13)
	material.roughness = 0.96
	plane.material = material
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	mesh_instance.mesh = plane
	root.add_child(mesh_instance)

	var body := StaticBody3D.new()
	body.name = "TerrainCollision"
	body.position.y = -0.5
	body.set_meta("surface_id", &"grass")
	body.set_meta("cell_id", cell.id)
	var shape := BoxShape3D.new()
	shape.size = Vector3(grid.cell_size, 1.0, grid.cell_size)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)
	return root

func height_at_world(_world_position: Vector3) -> float:
	return 0.0
