class_name RoadNetwork
extends Resource

var _junctions: Dictionary = {}
var _segments: Dictionary = {}

func add_junction(junction) -> Error:
	if junction == null:
		return ERR_INVALID_PARAMETER
	if _junctions.has(junction.id):
		return ERR_ALREADY_EXISTS
	if not junction.validation_errors().is_empty():
		return ERR_INVALID_DATA
	_junctions[junction.id] = junction
	return OK

func add_segment(segment) -> Error:
	if segment == null:
		return ERR_INVALID_PARAMETER
	if _segments.has(segment.id):
		return ERR_ALREADY_EXISTS
	if not segment.validation_errors().is_empty():
		return ERR_INVALID_DATA
	if not _junctions.has(segment.start_junction_id) or not _junctions.has(segment.end_junction_id):
		return ERR_DOES_NOT_EXIST
	_segments[segment.id] = segment
	_register_connection(_junctions[segment.start_junction_id], segment.id)
	_register_connection(_junctions[segment.end_junction_id], segment.id)
	return OK

func get_junction(junction_id: StringName):
	return _junctions.get(junction_id)

func get_segment(segment_id: StringName):
	return _segments.get(segment_id)

func junctions() -> Array:
	var result := _junctions.values()
	result.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return result

func segments() -> Array:
	var result := _segments.values()
	result.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return result

func connected_segments(junction_id: StringName) -> Array:
	var result: Array = []
	if not _junctions.has(junction_id):
		return result
	var junction = _junctions[junction_id]
	for road_id in junction.connected_road_ids:
		if _segments.has(road_id):
			var segment = _segments[road_id]
			if segment.start_junction_id == junction_id or segment.end_junction_id == junction_id:
				result.append(segment)
	result.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return result

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	for junction in junctions():
		for error in junction.validation_errors():
			errors.append("%s: %s" % [junction.id, error])
		for road_id in junction.connected_road_ids:
			if not _segments.has(road_id):
				errors.append("junction %s declares unknown road %s" % [junction.id, road_id])
				continue
			var segment = _segments[road_id]
			if segment.start_junction_id != junction.id and segment.end_junction_id != junction.id:
				errors.append("junction %s declares disconnected road %s" % [junction.id, road_id])
	for segment in segments():
		for error in segment.validation_errors():
			errors.append("%s: %s" % [segment.id, error])
		if not _junctions.has(segment.start_junction_id) or not _junctions.has(segment.end_junction_id):
			errors.append("road %s references missing endpoint" % segment.id)
	return errors

func _register_connection(junction, road_id: StringName) -> void:
	if road_id not in junction.connected_road_ids:
		junction.connected_road_ids.append(road_id)
