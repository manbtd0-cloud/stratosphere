extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var builder_script = load("res://src/traffic/traffic_lane_graph_builder.gd")
	var connector_script = load("res://src/traffic/traffic_lane_connector.gd")
	if builder_script == null or connector_script == null:
		fail("traffic connector scripts must exist")
		return
	var region := DrivingRegionFactory.create()
	var graph = builder_script.new().build(region.base_definition.road_network, region.base_definition.grid)
	var errors: PackedStringArray = graph.validation_errors()
	if not errors.is_empty():
		fail("canonical traffic lane graph invalid: %s" % errors)
		return
	var connectors: Array = graph.connectors_for_junction(&"junction.rural.1")
	if connectors.is_empty():
		fail("multi-road rural junction must derive traffic connectors")
		return
	for connector in connectors:
		var incoming = graph.get_lane(connector.from_lane_id)
		var outgoing = graph.get_lane(connector.to_lane_id)
		if incoming == null or outgoing == null:
			fail("connector lane references must resolve")
			return
		if incoming.end_junction_id != connector.junction_id or outgoing.start_junction_id != connector.junction_id:
			fail("connector must preserve legal travel direction through junction")
			return
		if incoming.source_road_segment_id == outgoing.source_road_segment_id:
			fail("Phase 3 connector generation must not create automatic U-turns")
			return
	var dangling = connector_script.new()
	dangling.id = &"traffic.connector.dangling"
	dangling.from_lane_id = &"traffic.missing.a"
	dangling.to_lane_id = &"traffic.missing.b"
	dangling.junction_id = &"junction.rural.1"
	if graph.add_connector(dangling) != ERR_DOES_NOT_EXIST:
		fail("dangling connector references must reject")
		return
	print("PASS: phase3 10_traffic_connectors")
	quit(0)
