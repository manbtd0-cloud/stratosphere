extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var builder_script = load("res://src/traffic/traffic_lane_graph_builder.gd")
	if builder_script == null:
		fail("TrafficLaneGraphBuilder script must exist")
		return
	var region := DrivingRegionFactory.create()
	var graph = builder_script.new().build(region.base_definition.road_network, region.base_definition.grid)
	if graph == null:
		fail("traffic lane graph must build")
		return
	var highway: Array = graph.lanes_for_road(&"road.highway.north")
	if highway.size() != 4:
		fail("four-lane highway must derive four traffic lanes")
		return
	var rural: Array = graph.lanes_for_road(&"road.rural.01")
	if rural.size() != 2:
		fail("two-lane rural road must derive two traffic lanes")
		return
	var forward := 0
	var reverse := 0
	for lane in rural:
		if lane.direction == &"forward": forward += 1
		if lane.direction == &"reverse": reverse += 1
		if lane.speed_limit_kph != 90.0 or lane.source_road_segment_id != &"road.rural.01":
			fail("lane must inherit source road speed/identity")
			return
		if lane.cell_ids.is_empty():
			fail("traffic lane must publish cell ownership")
			return
	if forward != 1 or reverse != 1:
		fail("rural road must have one lane per travel direction")
		return
	if rural[0].id == rural[1].id or is_equal_approx(rural[0].lateral_offset_m, rural[1].lateral_offset_m):
		fail("lane IDs/offsets must distinguish opposite travel lanes")
		return
	var dirt: Array = graph.lanes_for_road(&"road.dirt.cutthrough")
	if dirt.is_empty():
		fail("dirt lane metadata should exist for future uses")
		return
	for lane in dirt:
		if lane.civilian_enabled:
			fail("dirt trail must disable civilian traffic by default")
			return
	var repeat = builder_script.new().build(region.base_definition.road_network, region.base_definition.grid)
	if graph.fingerprint() != repeat.fingerprint():
		fail("traffic lane derivation must be deterministic")
		return
	print("PASS: phase3 09_traffic_lane_graph")
	quit(0)
