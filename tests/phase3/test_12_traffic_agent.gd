extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var agent_script = load("res://src/traffic/traffic_agent.gd")
	var definition_script = load("res://src/traffic/traffic_vehicle_definition.gd")
	if agent_script == null or definition_script == null:
		fail("traffic agent/definition scripts must exist")
		return
	var lane := _lane()
	var definition = definition_script.new()
	definition.id = &"traffic.vehicle.test"
	var agent = agent_script.new()
	var errors: PackedStringArray = agent.configure(definition, lane)
	if not errors.is_empty(): fail("valid traffic agent config rejected: %s" % errors); agent.free(); return
	if agent is VehicleController: fail("civilian traffic must not instantiate the player VehicleController"); agent.free(); return
	agent.position = Vector3.ZERO
	agent.linear_velocity = Vector3.ZERO
	var launch: Dictionary = agent.compute_control_state(0.1, INF, false)
	if float(launch.throttle) < 0.5 or float(launch.brake) > 0.01: fail("stopped traffic should accelerate toward lane speed"); agent.free(); return
	agent.linear_velocity = Vector3(0, 0, -18)
	var following: Dictionary = agent.compute_control_state(0.1, 6.0, false)
	if float(following.brake) <= 0.1: fail("traffic must brake when following gap is unsafe"); agent.free(); return
	var blocked: Dictionary = agent.compute_control_state(0.1, INF, true)
	if float(blocked.brake) < 0.99 or float(blocked.throttle) > 0.01: fail("blocked lane must command full brake"); agent.free(); return
	agent.position = Vector3(55, 0, -20)
	var recovery := false
	for _i in range(4):
		var state: Dictionary = agent.compute_control_state(1.0, INF, false)
		recovery = recovery or bool(state.recovery_requested)
	if not recovery: fail("sustained large lane divergence must request recovery"); agent.free(); return
	agent.set_simulation_level(&"mid")
	if not agent.freeze or not agent.visible: fail("mid traffic must be frozen/simplified but visible"); agent.free(); return
	agent.set_simulation_level(&"far")
	if not agent.freeze or agent.visible: fail("far traffic body must be frozen and hidden") ; agent.free(); return
	agent.set_simulation_level(&"near")
	if agent.freeze or not agent.visible: fail("near traffic must return to dynamic visible body"); agent.free(); return
	agent.free()
	print("PASS: phase3 12_traffic_agent")
	quit(0)

func _lane() -> TrafficLane:
	var lane := TrafficLane.new()
	lane.id = &"traffic.road.test.f0"
	lane.source_road_segment_id = &"road.test"
	lane.direction = &"forward"
	lane.lateral_offset_m = 1.7
	lane.lane_width_m = 3.4
	lane.speed_limit_kph = 72.0
	lane.start_junction_id = &"junction.a"
	lane.end_junction_id = &"junction.b"
	lane.sampled_positions = PackedVector3Array([Vector3(0,0,0), Vector3(0,0,-100), Vector3(0,0,-200)])
	lane.cell_ids = [&"world.proving.cp00_p00"]
	return lane
