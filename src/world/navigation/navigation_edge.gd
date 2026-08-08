class_name NavigationEdge
extends Resource

@export var id: StringName = &""
@export var from_node_id: StringName = &""
@export var to_node_id: StringName = &""
@export var road_segment_id: StringName = &""
@export var cost_m: float = 0.0
@export var sampled_positions: PackedVector3Array = PackedVector3Array()

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty(): errors.append("navigation edge id must not be empty")
	if from_node_id.is_empty() or to_node_id.is_empty(): errors.append("navigation edge endpoints must not be empty")
	if from_node_id == to_node_id: errors.append("navigation edge endpoints must differ")
	if road_segment_id.is_empty(): errors.append("navigation edge road segment id must not be empty")
	if cost_m <= 0.0: errors.append("navigation edge cost must be positive")
	if sampled_positions.size() < 2: errors.append("navigation edge requires at least two sampled positions")
	return errors
