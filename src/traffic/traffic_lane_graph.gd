class_name TrafficLaneGraph
extends RefCounted

var _lanes: Dictionary = {}
var _connectors: Dictionary = {}

func add_lane(lane: TrafficLane) -> Error:
	if lane == null or not lane.validation_errors().is_empty(): return ERR_INVALID_DATA
	if _lanes.has(lane.id): return ERR_ALREADY_EXISTS
	_lanes[lane.id] = lane
	return OK

func add_connector(connector: TrafficLaneConnector) -> Error:
	if connector == null or not connector.validation_errors().is_empty(): return ERR_INVALID_DATA
	if _connectors.has(connector.id): return ERR_ALREADY_EXISTS
	if not _lanes.has(connector.from_lane_id) or not _lanes.has(connector.to_lane_id): return ERR_DOES_NOT_EXIST
	var incoming: TrafficLane = _lanes[connector.from_lane_id]
	var outgoing: TrafficLane = _lanes[connector.to_lane_id]
	if incoming.end_junction_id != connector.junction_id or outgoing.start_junction_id != connector.junction_id:
		return ERR_INVALID_DATA
	_connectors[connector.id] = connector
	return OK

func get_lane(lane_id: StringName) -> TrafficLane:
	return _lanes.get(lane_id) as TrafficLane

func get_connector(connector_id: StringName) -> TrafficLaneConnector:
	return _connectors.get(connector_id) as TrafficLaneConnector

func lane_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for lane_id in _lanes.keys(): result.append(lane_id)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result

func connector_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for connector_id in _connectors.keys(): result.append(connector_id)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result

func lanes_for_road(road_id: StringName) -> Array[TrafficLane]:
	var result: Array[TrafficLane] = []
	for lane_id in lane_ids():
		var lane := get_lane(lane_id)
		if lane.source_road_segment_id == road_id: result.append(lane)
	return result

func connectors_for_junction(junction_id: StringName) -> Array[TrafficLaneConnector]:
	var result: Array[TrafficLaneConnector] = []
	for connector_id in connector_ids():
		var connector := get_connector(connector_id)
		if connector.junction_id == junction_id: result.append(connector)
	return result

func incoming_lanes(junction_id: StringName, civilian_only: bool = false) -> Array[TrafficLane]:
	var result: Array[TrafficLane] = []
	for lane_id in lane_ids():
		var lane := get_lane(lane_id)
		if lane.end_junction_id == junction_id and (not civilian_only or lane.civilian_enabled): result.append(lane)
	return result

func outgoing_lanes(junction_id: StringName, civilian_only: bool = false) -> Array[TrafficLane]:
	var result: Array[TrafficLane] = []
	for lane_id in lane_ids():
		var lane := get_lane(lane_id)
		if lane.start_junction_id == junction_id and (not civilian_only or lane.civilian_enabled): result.append(lane)
	return result

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	for lane_id in lane_ids():
		for error in get_lane(lane_id).validation_errors(): errors.append("%s: %s" % [lane_id, error])
	for connector_id in connector_ids():
		var connector := get_connector(connector_id)
		for error in connector.validation_errors(): errors.append("%s: %s" % [connector_id, error])
		if not _lanes.has(connector.from_lane_id) or not _lanes.has(connector.to_lane_id):
			errors.append("%s references missing traffic lane" % connector_id)
			continue
		var incoming := get_lane(connector.from_lane_id)
		var outgoing := get_lane(connector.to_lane_id)
		if incoming.end_junction_id != connector.junction_id or outgoing.start_junction_id != connector.junction_id:
			errors.append("%s violates junction travel direction" % connector_id)
	return errors

func fingerprint() -> String:
	var text := ""
	for lane_id in lane_ids():
		var lane := get_lane(lane_id)
		text += "%s|%s|%s|%.3f|%.3f|%s|%s|%s|%s;" % [lane.id, lane.source_road_segment_id, lane.direction, lane.lateral_offset_m, lane.speed_limit_kph, lane.start_junction_id, lane.end_junction_id, lane.civilian_enabled, lane.cell_ids]
	for connector_id in connector_ids():
		var connector := get_connector(connector_id)
		text += "%s>%s>%s@%s;" % [connector.id, connector.from_lane_id, connector.to_lane_id, connector.junction_id]
	return text.sha256_text()
