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
