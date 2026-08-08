class_name TrafficLane
extends Resource

@export var id: StringName = &""
@export var source_road_segment_id: StringName = &""
@export var direction: StringName = &"forward"
@export var lateral_offset_m: float = 0.0
@export var lane_width_m: float = 3.4
@export var speed_limit_kph: float = 50.0
@export var start_junction_id: StringName = &""
@export var end_junction_id: StringName = &""
@export var sampled_positions: PackedVector3Array = PackedVector3Array()
@export var cell_ids: Array[StringName] = []
@export var civilian_enabled: bool = true

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty(): errors.append("traffic lane id must not be empty")
	if source_road_segment_id.is_empty(): errors.append("traffic lane source road id must not be empty")
	if direction not in [&"forward", &"reverse"]: errors.append("unsupported traffic lane direction: %s" % direction)
	if lane_width_m <= 0.0: errors.append("traffic lane width must be positive")
	if speed_limit_kph <= 0.0: errors.append("traffic lane speed must be positive")
	if start_junction_id.is_empty() or end_junction_id.is_empty(): errors.append("traffic lane junction IDs must not be empty")
	if start_junction_id == end_junction_id: errors.append("traffic lane junction IDs must differ")
	if sampled_positions.size() < 2: errors.append("traffic lane requires at least two sampled positions")
	if cell_ids.is_empty(): errors.append("traffic lane must publish cell ownership")
	return errors
