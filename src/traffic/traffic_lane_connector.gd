class_name TrafficLaneConnector
extends Resource

@export var id: StringName = &""
@export var from_lane_id: StringName = &""
@export var to_lane_id: StringName = &""
@export var junction_id: StringName = &""

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty(): errors.append("traffic connector id must not be empty")
	if from_lane_id.is_empty() or to_lane_id.is_empty(): errors.append("traffic connector lane IDs must not be empty")
	if from_lane_id == to_lane_id: errors.append("traffic connector lanes must differ")
	if junction_id.is_empty(): errors.append("traffic connector junction ID must not be empty")
	return errors
