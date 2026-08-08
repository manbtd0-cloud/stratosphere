extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var definition_script = load("res://src/world/proving/proving_region_definition.gd")
	var factory_script = load("res://src/world/proving/proving_region_factory.gd")
	if definition_script == null or factory_script == null:
		fail("proving region definition/factory scripts must exist")
		return
	var definition = factory_script.create()
	if definition == null:
		fail("factory must create a proving region definition")
		return
	var errors: PackedStringArray = definition.validation_errors()
	if not errors.is_empty():
		fail("proving region definition invalid: %s" % errors)
		return
	if definition.cells.size() != 144:
		fail("proving region must define all 12x12 streaming cells")
		return
	var profile_ids := {}
	var hill_delta := 0.0
	var has_service := false
	var has_dirt := false
	for segment in definition.road_network.segments():
		profile_ids[segment.profile_id] = true
		if segment.profile_id == &"service":
			has_service = true
		if segment.profile_id == &"dirt_trail":
			has_dirt = true
		if segment.profile_id == &"hill_two_lane":
			var min_y: float = INF
			var max_y: float = -INF
			for i in segment.centerline.point_count:
				var y: float = float(segment.centerline.get_point_position(i).y)
				min_y = minf(min_y, y)
				max_y = maxf(max_y, y)
			hill_delta = maxf(hill_delta, max_y - min_y)
	for required in [&"highway", &"rural_two_lane", &"hill_two_lane", &"service", &"dirt_trail"]:
		if not profile_ids.has(required):
			fail("missing road profile in proving network: %s" % required)
			return
	if not definition.has_closed_loop([&"highway", &"rural_two_lane"]):
		fail("proving region needs a closed high-speed/rural loop")
		return
	if hill_delta < 25.0:
		fail("hill branch must include meaningful elevation change")
		return
	if not has_service or not has_dirt:
		fail("service and dirt branches are required")
		return
	if definition.spawn_surface_id != &"asphalt_dry":
		fail("player spawn must be designated on asphalt")
		return
	if definition.authored_cell_coords.size() < 6 or definition.authored_cell_coords.size() >= 144:
		fail("authored high-detail footprint must be concentrated in a subset of grid cells")
		return
	print("PASS: phase2 11_proving_region_definition")
	quit(0)
