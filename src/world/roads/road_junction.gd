class_name RoadJunction
extends Resource

const ALLOWED_CLASSES := [&"endpoint", &"t_junction", &"crossroad", &"highway_merge", &"highway_diverge"]

@export var id: StringName = &""
@export var position: Vector3 = Vector3.ZERO
@export var connected_road_ids: Array[StringName] = []
@export var junction_class: StringName = &"endpoint"

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	connected_road_ids = _deduplicated(connected_road_ids)
	if id.is_empty():
		errors.append("junction id must not be empty")
	if junction_class not in ALLOWED_CLASSES:
		errors.append("unsupported junction class: %s" % junction_class)
	if not position.is_finite():
		errors.append("junction position must be finite")
	return errors

func _deduplicated(values: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		if not value.is_empty() and value not in result:
			result.append(value)
	return result
