class_name NavigationGraphBuilder
extends RefCounted

var _sampler := RoadSplineSampler.new()

func build(network: RoadNetwork) -> NavigationGraph:
	if network == null: return null
	var graph := NavigationGraph.new()
	for junction in network.junctions():
		if graph.add_node(junction.id, junction.position) != OK: return null
	for segment in network.segments():
		var samples := _sampler.sample(segment, 8.0)
		if samples.size() < 2: return null
		var positions := PackedVector3Array()
		for sample in samples: positions.append(sample.position)
		var cost: float = samples[-1].accumulated_distance_m
		if segment.travel_direction_policy != &"reverse_only":
			if graph.add_edge(_edge(segment, true, positions, cost)) != OK: return null
		if segment.travel_direction_policy == &"bidirectional" or segment.travel_direction_policy == &"reverse_only":
			var reversed := PackedVector3Array()
			for index in range(positions.size() - 1, -1, -1): reversed.append(positions[index])
			if graph.add_edge(_edge(segment, false, reversed, cost)) != OK: return null
	return graph

func _edge(segment: RoadSegment, forward: bool, positions: PackedVector3Array, cost: float) -> NavigationEdge:
	var edge := NavigationEdge.new()
	edge.id = StringName("nav.%s.%s" % [segment.id, "forward" if forward else "reverse"])
	edge.from_node_id = segment.start_junction_id if forward else segment.end_junction_id
	edge.to_node_id = segment.end_junction_id if forward else segment.start_junction_id
	edge.road_segment_id = segment.id
	edge.cost_m = cost
	edge.sampled_positions = positions
	return edge
