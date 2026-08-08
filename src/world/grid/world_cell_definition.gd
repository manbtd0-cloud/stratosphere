class_name WorldCellDefinition
extends Resource

@export var id: StringName = &""
@export var coord: Vector2i = Vector2i.ZERO
@export var terrain_backend_key: StringName = &"builtin"
@export var road_segment_ids: Array[StringName] = []
@export var surface_region_ids: Array[StringName] = []
@export var environment_group_ids: Array[StringName] = []
@export var prop_group_ids: Array[StringName] = []
@export var runtime_priority: int = 0
@export var persistent_state_namespace: StringName = &"world.proving"

func validation_errors(grid) -> PackedStringArray:
	var errors := PackedStringArray()
	road_segment_ids = _deduplicated(road_segment_ids)
	surface_region_ids = _deduplicated(surface_region_ids)
	environment_group_ids = _deduplicated(environment_group_ids)
	prop_group_ids = _deduplicated(prop_group_ids)
	if grid == null:
		errors.append("world grid must not be null")
		return errors
	if not grid.is_valid_coord(coord):
		errors.append("cell coordinate is outside world grid: %s" % coord)
	if id.is_empty():
		errors.append("cell id must not be empty")
	elif id != grid.coord_to_id(coord):
		errors.append("cell id does not match coordinate: %s" % id)
	if terrain_backend_key.is_empty():
		errors.append("terrain backend key must not be empty")
	if persistent_state_namespace.is_empty():
		errors.append("persistent state namespace must not be empty")
	return errors

func _deduplicated(values: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	var seen: Dictionary = {}
	for value in values:
		if value.is_empty() or seen.has(value):
			continue
		seen[value] = true
		result.append(value)
	return result
