class_name BuiltinTerrainBackend
extends TerrainBackendAdapter

func backend_id() -> StringName:
	return &"builtin_grid"

func supports(feature: StringName) -> bool:
	return feature in [&"cell_visual", &"cell_collision", &"surface_metadata", &"height_interface", &"height_sampling"]

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

func sample_height(world_position: Vector3) -> float:
	var x := world_position.x
	var z := world_position.z
	var rolling := sin(x * 0.0018) * 5.0 + cos(z * 0.0015) * 4.0 + sin((x + z) * 0.0009) * 3.0
	var dx := x + 430.0
	var dz := z + 760.0
	var hill_distance_sq := dx * dx + dz * dz
	var hill := 84.0 * exp(-hill_distance_sq / (2.0 * 430.0 * 430.0))
	var highway_weight := exp(-pow(z - 500.0, 2.0) / (2.0 * 120.0 * 120.0))
	var natural_height := rolling + hill
	return lerpf(natural_height, rolling * 0.18, highway_weight)

func sample_normal(world_position: Vector3) -> Vector3:
	var epsilon := 2.0
	var left := sample_height(world_position + Vector3(-epsilon, 0.0, 0.0))
	var right := sample_height(world_position + Vector3(epsilon, 0.0, 0.0))
	var back := sample_height(world_position + Vector3(0.0, 0.0, -epsilon))
	var forward := sample_height(world_position + Vector3(0.0, 0.0, epsilon))
	return Vector3(left - right, epsilon * 2.0, back - forward).normalized()

func height_at_world(world_position: Vector3) -> float:
	return sample_height(world_position)
