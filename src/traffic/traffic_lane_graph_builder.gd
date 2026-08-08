class_name TrafficLaneGraphBuilder
extends RefCounted

var _sampler := RoadSplineSampler.new()

func build(network: RoadNetwork, grid: WorldGrid) -> TrafficLaneGraph:
	if network == null or grid == null: return null
	var graph := TrafficLaneGraph.new()
	for segment in network.segments():
		var profile := RoadProfile.for_id(segment.profile_id)
		if profile == null: return null
		for lane in _lanes_for_segment(segment, profile, grid):
			if graph.add_lane(lane) != OK: return null
	_build_connectors(network, graph)
	return graph

func _lanes_for_segment(segment: RoadSegment, profile: RoadProfile, grid: WorldGrid) -> Array[TrafficLane]:
	var result: Array[TrafficLane] = []
	var samples := _sampler.sample(segment, 6.0)
	if samples.size() < 2: return result
	var centers: Array[float] = []
	for index in range(profile.lane_count):
		centers.append(-profile.road_width_m() * 0.5 + profile.lane_width_m * (float(index) + 0.5))
	if segment.travel_direction_policy == &"forward_only":
		for index in range(centers.size()): result.append(_lane(segment, profile, grid, samples, &"forward", index, centers[index]))
	elif segment.travel_direction_policy == &"reverse_only":
		for index in range(centers.size()): result.append(_lane(segment, profile, grid, samples, &"reverse", index, centers[index]))
	elif profile.lane_count == 1:
		result.append(_lane(segment, profile, grid, samples, &"forward", 0, 0.0))
	else:
		var half := profile.lane_count / 2
		var forward_index := 0
		var reverse_index := 0
		for center in centers:
			if center > 0.0:
				result.append(_lane(segment, profile, grid, samples, &"forward", forward_index, center)); forward_index += 1
			elif center < 0.0:
				result.append(_lane(segment, profile, grid, samples, &"reverse", reverse_index, center)); reverse_index += 1
		if half > 0 and result.is_empty(): return result
	return result

func _lane(segment: RoadSegment, profile: RoadProfile, grid: WorldGrid, samples: Array[RoadSample], direction: StringName, lane_index: int, offset: float) -> TrafficLane:
	var lane := TrafficLane.new()
	lane.id = StringName("traffic.%s.%s%d" % [segment.id, "f" if direction == &"forward" else "r", lane_index])
	lane.source_road_segment_id = segment.id
	lane.direction = direction
	lane.lateral_offset_m = offset
	lane.lane_width_m = profile.lane_width_m
	lane.speed_limit_kph = segment.speed_limit_kph
	lane.start_junction_id = segment.start_junction_id if direction == &"forward" else segment.end_junction_id
	lane.end_junction_id = segment.end_junction_id if direction == &"forward" else segment.start_junction_id
	lane.civilian_enabled = profile.id != &"dirt_trail"
	var original := PackedVector3Array()
	for sample in samples: original.append(sample.position + sample.right * offset)
	if direction == &"forward":
		lane.sampled_positions = original
	else:
		var reversed := PackedVector3Array()
		for index in range(original.size() - 1, -1, -1): reversed.append(original[index])
		lane.sampled_positions = reversed
	var seen_cells: Dictionary = {}
	for position in lane.sampled_positions:
		var coord := grid.world_to_coord(position)
		if not grid.is_valid_coord(coord): continue
		var cell_id := grid.coord_to_id(coord)
		if not seen_cells.has(cell_id):
			seen_cells[cell_id] = true
			lane.cell_ids.append(cell_id)
	return lane

func _build_connectors(network: RoadNetwork, graph: TrafficLaneGraph) -> void:
	for junction in network.junctions():
		var incoming := graph.incoming_lanes(junction.id, true)
		var outgoing := graph.outgoing_lanes(junction.id, true)
		for from_lane in incoming:
			for to_lane in outgoing:
				if from_lane.source_road_segment_id == to_lane.source_road_segment_id: continue
				var connector := TrafficLaneConnector.new()
				connector.id = StringName("traffic.connector.%s.%s.%s" % [junction.id, from_lane.id, to_lane.id])
				connector.from_lane_id = from_lane.id
				connector.to_lane_id = to_lane.id
				connector.junction_id = junction.id
				assert(graph.add_connector(connector) == OK)
