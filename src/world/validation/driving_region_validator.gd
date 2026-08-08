class_name DrivingRegionValidator
extends RefCounted

func validate(
	region: DrivingRegionDefinition,
	lane_graph: TrafficLaneGraph,
	traffic_definitions: Array[TrafficVehicleDefinition],
	runtime: Node3D = null
) -> PackedStringArray:
	var errors := PackedStringArray()
	if region == null:
		errors.append("driving region must not be null")
		return errors
	for error in region.validate(): errors.append(error)
	if lane_graph == null:
		errors.append("traffic lane graph must not be null")
	else:
		for error in lane_graph.validation_errors(): errors.append(error)
		_validate_dirt_traffic(region, lane_graph, errors)
	_validate_traffic_definitions(traffic_definitions, errors)
	_validate_facility_hooks(region, errors)
	if runtime != null:
		_validate_runtime_environment(region, runtime, errors)
	errors.sort()
	return errors

func _validate_traffic_definitions(definitions: Array[TrafficVehicleDefinition], errors: PackedStringArray) -> void:
	var seen: Dictionary = {}
	if definitions.is_empty(): errors.append("traffic roster must not be empty")
	for definition in definitions:
		if definition == null:
			errors.append("traffic vehicle definition must not be null")
			continue
		if seen.has(definition.id): errors.append("duplicate traffic vehicle id: %s" % definition.id)
		seen[definition.id] = true
		for error in definition.validation_errors(): errors.append("%s: %s" % [definition.id, error])

func _validate_dirt_traffic(region: DrivingRegionDefinition, lane_graph: TrafficLaneGraph, errors: PackedStringArray) -> void:
	for lane_id in lane_graph.lane_ids():
		var lane: TrafficLane = lane_graph.get_lane(lane_id)
		if lane == null or not lane.civilian_enabled: continue
		var segment: RoadSegment = region.base_definition.road_network.get_segment(lane.source_road_segment_id) as RoadSegment
		if segment != null and segment.profile_id == &"dirt_trail":
			errors.append("dirt_trail lane enables civilian traffic by default: %s" % lane_id)

func _validate_facility_hooks(region: DrivingRegionDefinition, errors: PackedStringArray) -> void:
	for facility_id in [&"garage", &"dealership"]:
		if not region.facility_hooks.has(facility_id):
			errors.append("missing %s facility hook" % facility_id)
			continue
		var transform: Variant = region.facility_hooks[facility_id]
		if not transform is Transform3D or not (transform as Transform3D).origin.is_finite():
			errors.append("invalid %s facility hook" % facility_id)

func _validate_runtime_environment(region: DrivingRegionDefinition, runtime: Node3D, errors: PackedStringArray) -> void:
	var environment := runtime.get_node_or_null("EnvironmentRoot/Phase3Environment")
	if environment == null:
		errors.append("Phase 3 runtime environment root missing")
		return
	var authored_ids: Dictionary = {}
	for coord in region.authored_cell_coords: authored_ids[region.base_definition.grid.coord_to_id(coord)] = true
	var seen: Dictionary = {}
	for child in environment.get_children():
		if not child is Node3D:
			errors.append("environment group must be Node3D")
			continue
		var cell_id: StringName = child.get_meta("cell_id", &"")
		if cell_id.is_empty() or not authored_ids.has(cell_id):
			errors.append("environment group missing stable cell ownership: %s" % child.name)
			continue
		if seen.has(cell_id): errors.append("duplicate environment cell ownership: %s" % cell_id)
		seen[cell_id] = true
		if String(child.get_meta("content_fingerprint", "")).is_empty(): errors.append("environment cell missing deterministic content fingerprint: %s" % cell_id)
	if seen.size() != region.authored_cell_coords.size():
		errors.append("runtime environment authored-cell count mismatch")
	if runtime.get_node_or_null("RoadsRoot/Phase3Presentation") == null:
		errors.append("Phase 3 road presentation root missing")
