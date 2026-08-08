class_name TrafficSimulationPolicy
extends Resource

@export var near_enter_m: float = 120.0
@export var near_exit_m: float = 145.0
@export var mid_enter_m: float = 450.0
@export var mid_exit_m: float = 500.0

func level_for(entity_id: StringName, distance_m: float, previous_level: StringName = &"") -> StringName:
	if entity_id == &"player":
		return &"player"
	var distance := maxf(distance_m, 0.0)
	match previous_level:
		&"near":
			if distance <= near_exit_m: return &"near"
			if distance <= mid_enter_m: return &"mid"
			return &"far"
		&"mid":
			if distance < near_enter_m: return &"near"
			if distance <= mid_exit_m: return &"mid"
			return &"far"
		&"far":
			if distance < near_enter_m: return &"near"
			if distance < mid_enter_m: return &"mid"
			return &"far"
	if distance <= near_enter_m: return &"near"
	if distance <= mid_enter_m: return &"mid"
	return &"far"

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if near_enter_m <= 0.0: errors.append("near enter distance must be positive")
	if near_exit_m < near_enter_m: errors.append("near exit must be at least near enter")
	if mid_enter_m <= near_exit_m: errors.append("mid enter must exceed near exit")
	if mid_exit_m < mid_enter_m: errors.append("mid exit must be at least mid enter")
	return errors
