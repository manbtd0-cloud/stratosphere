class_name SimulationClock
extends RefCounted

const MAX_FRAME_DELTA_SECONDS: float = 0.25

var _tick_duration_seconds: float
var _accumulator_seconds: float = 0.0


func _init(ticks_per_second: float = 120.0) -> void:
	assert(ticks_per_second > 0.0, "ticks_per_second must be positive")
	_tick_duration_seconds = 1.0 / ticks_per_second


func advance(real_delta: float) -> int:
	if real_delta <= 0.0:
		return 0

	_accumulator_seconds += minf(real_delta, MAX_FRAME_DELTA_SECONDS)
	var tick_count := floori(_accumulator_seconds / _tick_duration_seconds)
	_accumulator_seconds -= float(tick_count) * _tick_duration_seconds
	return tick_count


func get_alpha() -> float:
	return clampf(_accumulator_seconds / _tick_duration_seconds, 0.0, 1.0)
