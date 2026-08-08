extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var builder_script = load("res://src/world/navigation/navigation_graph_builder.gd")
	if builder_script == null:
		fail("NavigationGraphBuilder script must exist")
		return
	var region := DrivingRegionFactory.create()
	var graph = builder_script.new().build(region.base_definition.road_network)
	if graph == null:
		fail("navigation graph must build from authoritative roads")
		return
	var errors: PackedStringArray = graph.validation_errors()
	if not errors.is_empty():
		fail("canonical navigation graph invalid: %s" % errors)
		return
	if graph.node_count() != region.base_definition.road_network.junctions().size():
		fail("every authoritative road junction must become a navigation node")
		return
	for segment in region.base_definition.road_network.segments():
		var forward_id := StringName("nav.%s.forward" % segment.id)
		if graph.get_edge(forward_id) == null:
			fail("missing forward navigation edge for %s" % segment.id)
			return
		if segment.travel_direction_policy == &"bidirectional":
			var reverse_id := StringName("nav.%s.reverse" % segment.id)
			if graph.get_edge(reverse_id) == null:
				fail("bidirectional road missing reverse edge: %s" % segment.id)
				return
	var one_way_network := _one_way_network()
	var one_way_graph = builder_script.new().build(one_way_network)
	if one_way_graph.get_edge(&"nav.road.oneway.forward") == null:
		fail("forward-only road must produce forward edge")
		return
	if one_way_graph.get_edge(&"nav.road.oneway.reverse") != null:
		fail("forward-only road must not produce reverse edge")
		return
	print("PASS: phase3 07_navigation_graph")
	quit(0)

func _one_way_network() -> RoadNetwork:
	var network := RoadNetwork.new()
	for spec in [[&"junction.ow.a", Vector3.ZERO], [&"junction.ow.b", Vector3(0, 0, -100)]]:
		var junction := RoadJunction.new()
		junction.id = spec[0]
		junction.position = spec[1]
		assert(network.add_junction(junction) == OK)
	var segment := RoadSegment.new()
	segment.id = &"road.oneway"
	segment.start_junction_id = &"junction.ow.a"
	segment.end_junction_id = &"junction.ow.b"
	segment.profile_id = &"service"
	segment.travel_direction_policy = &"forward_only"
	segment.centerline = Curve3D.new()
	segment.centerline.add_point(Vector3.ZERO)
	segment.centerline.add_point(Vector3(0, 0, -100))
	assert(network.add_segment(segment) == OK)
	return network
