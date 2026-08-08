class_name TerrainBackendAdapter
extends RefCounted

func backend_id() -> StringName:
	return &"abstract"

func create_cell(_cell: WorldCellDefinition, _grid: WorldGrid) -> Node3D:
	return null

func release_cell(cell_node: Node3D) -> void:
	if cell_node == null or not is_instance_valid(cell_node):
		return
	if cell_node.is_inside_tree():
		cell_node.queue_free()
	else:
		cell_node.free()

func supports(_feature: StringName) -> bool:
	return false

func sample_height(_world_position: Vector3) -> float:
	return 0.0

func sample_normal(world_position: Vector3) -> Vector3:
	var epsilon := 2.0
	var left := sample_height(world_position + Vector3(-epsilon, 0.0, 0.0))
	var right := sample_height(world_position + Vector3(epsilon, 0.0, 0.0))
	var back := sample_height(world_position + Vector3(0.0, 0.0, -epsilon))
	var forward := sample_height(world_position + Vector3(0.0, 0.0, epsilon))
	return Vector3(left - right, epsilon * 2.0, back - forward).normalized()
