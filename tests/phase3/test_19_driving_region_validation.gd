extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var validator_script = load("res://src/world/validation/driving_region_validator.gd")
	if validator_script == null:
		fail("DrivingRegionValidator script must exist")
		return
	var validator = validator_script.new()
	var region := DrivingRegionFactory.create()
	var lane_graph := TrafficLaneGraphBuilder.new().build(region.base_definition.road_network, region.base_definition.grid)
	var definitions := TrafficRosterFactory.create_development_roster()
	var runtime := DrivingRegionBuilder.new().build(region)
	var errors: PackedStringArray = validator.validate(region, lane_graph, definitions, runtime)
	if not errors.is_empty(): fail("canonical Phase 3 region must validate: %s" % errors); runtime.free(); return
	var duplicate_definitions := definitions.duplicate()
	duplicate_definitions.append(definitions[0])
	if not _contains(validator.validate(region, lane_graph, duplicate_definitions, runtime), "duplicate traffic vehicle id"):
		fail("validator must reject duplicate traffic roster IDs"); runtime.free(); return
	var dirt_graph := TrafficLaneGraphBuilder.new().build(region.base_definition.road_network, region.base_definition.grid)
	var dirt_lanes := dirt_graph.lanes_for_road(&"road.dirt.cutthrough")
	dirt_lanes[0].civilian_enabled = true
	if not _contains(validator.validate(region, dirt_graph, definitions, runtime), "dirt_trail"):
		fail("validator must reject civilian traffic enabled on dirt trail by default"); runtime.free(); return
	var garage_transform: Transform3D = region.facility_hooks[&"garage"]
	region.facility_hooks.erase(&"garage")
	if not _contains(validator.validate(region, lane_graph, definitions, runtime), "garage"):
		fail("validator must reject missing garage hook"); runtime.free(); return
	region.facility_hooks[&"garage"] = garage_transform
	var environment := runtime.get_node("EnvironmentRoot/Phase3Environment")
	var first_cell := environment.get_child(0)
	var original_cell_id: StringName = first_cell.get_meta("cell_id")
	first_cell.set_meta("cell_id", &"")
	if not _contains(validator.validate(region, lane_graph, definitions, runtime), "cell ownership"):
		fail("validator must reject environment groups without stable cell ownership"); runtime.free(); return
	first_cell.set_meta("cell_id", original_cell_id)
	runtime.free()
	print("PASS: phase3 19_driving_region_validation")
	quit(0)

func _contains(values: PackedStringArray, fragment: String) -> bool:
	for value in values:
		if String(value).contains(fragment): return true
	return false
