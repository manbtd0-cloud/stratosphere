class_name WorldStreamingConfig
extends Resource

@export var gameplay_radius_cells: int = 1
@export var visual_radius_cells: int = 3
@export var predictive_lookahead_seconds: float = 2.25
@export var unload_hysteresis_cells: int = 1

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if gameplay_radius_cells < 0:
		errors.append("gameplay radius must not be negative")
	if visual_radius_cells < gameplay_radius_cells:
		errors.append("visual radius must cover gameplay radius")
	if predictive_lookahead_seconds < 0.0:
		errors.append("predictive lookahead must not be negative")
	if unload_hysteresis_cells < 0:
		errors.append("unload hysteresis must not be negative")
	return errors
