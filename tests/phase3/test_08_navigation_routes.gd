extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var builder_script = load("res://src/world/navigation/navigation_graph_builder.gd")
	var service_script = load("res://src/world/navigation/navigation_service.gd")
	if builder_script == null or service_script == null:
		fail("navigation builder/service scripts must exist")
		return
	var region := DrivingRegionFactory.create()
	var graph = builder_script.new().build(region.base_definition.road_network)
	var service = service_script.new(graph)
	var route: Array[StringName] = service.find_route(&"junction.highway.ne", &"junction.hill.2")
	if route.is_empty():
		fail("highway -> rural -> hill route must be connected in Phase 3")
		return
	var segment_ids: Array[StringName] = service.route_segment_ids(route)
	if &"road.connector.highway_rural" not in segment_ids:
		fail("cross-region route must use the deliberate highway/rural connector")
		return
	if &"road.hill.climb_b" not in segment_ids:
		fail("hill destination route must reach the hill branch")
		return
	var nearest: StringName = service.nearest_edge(Vector3(140, 0, 70))
	if nearest.is_empty():
		fail("nearest-edge lookup must resolve near service area")
		return
	var one_way_graph = _one_way_graph(builder_script)
	var one_way_service = service_script.new(one_way_graph)
	if not one_way_service.find_route(&"junction.ow.a", &"junction.ow.b").size() == 1:
		fail("forward traversal on one-way road must route")
		return
	if not one_way_service.find_route(&"junction.ow.b", &"junction.ow.a").is_empty():
		fail("reverse traversal on forward-only road must reject")
		return
	var repeat: Array[StringName] = service.find_route(&"junction.highway.ne", &"junction.hill.2")
	if repeat != route:
		fail("route search must be deterministic")
		return
	print("PASS: phase3 08_navigation_routes")
	quit(0)

func _one_way_graph(builder_script):
	var network := RoadNetwork.new()
	var a := RoadJunction.new(); a.id = &"junction.ow.a"; a.position = Vector3.ZERO
	var b := RoadJunction.new(); b.id = &"junction.ow.b"; b.position = Vector3(0, 0, -100)
	assert(network.add_junction(a) == OK); assert(network.add_junction(b) == OK)
	var s := RoadSegment.new(); s.id = &"road.oneway"; s.start_junction_id = a.id; s.end_junction_id = b.id; s.profile_id = &"service"; s.travel_direction_policy = &"forward_only"; s.centerline = Curve3D.new(); s.centerline.add_point(a.position); s.centerline.add_point(b.position)
	assert(network.add_segment(s) == OK)
	return builder_script.new().build(network)
