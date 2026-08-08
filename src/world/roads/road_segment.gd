class_name RoadSegment
extends Resource

@export var id: StringName = &""
@export var start_junction_id: StringName = &""
@export var end_junction_id: StringName = &""
@export var centerline: Curve3D = Curve3D.new()
@export var profile_id: StringName = &"rural_two_lane"
@export var lane_count: int = 0
@export var travel_direction_policy: StringName = &"bidirectional"
@export var surface_id: StringName = &"asphalt_dry"
@export var speed_limit_kph: float = 80.0
@export var banking_degrees: float = 0.0
@export var shoulder_width_override_m: float = -1.0
@export var navigation_tags: Array[StringName] = []

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("road segment id must not be empty")
	if start_junction_id.is_empty() or end_junction_id.is_empty():
		errors.append("road segment endpoint IDs must not be empty")
	elif start_junction_id == end_junction_id:
		errors.append("road segment endpoints must differ")
	if centerline == null or centerline.point_count < 2:
		errors.append("road segment curve requires at least two control points")
	if RoadProfile.for_id(profile_id) == null:
		errors.append("unknown road profile: %s" % profile_id)
	if surface_id not in [&"asphalt_dry", &"asphalt_wet", &"gravel", &"dirt", &"grass"]:
		errors.append("unsupported road surface: %s" % surface_id)
	if lane_count < 0:
		errors.append("lane count override must not be negative")
	if speed_limit_kph <= 0.0:
		errors.append("speed limit must be positive")
	if shoulder_width_override_m < -1.0:
		errors.append("shoulder override must be -1 or non-negative")
	return errors
