extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var config_script = load("res://src/world/streaming/world_streaming_config.gd")
	var policy_script = load("res://src/world/streaming/world_streaming_policy.gd")
	if config_script == null or policy_script == null:
		fail("streaming policy scripts must exist")
		return
	var grid := WorldGrid.new()
	var config = config_script.new()
	if config.gameplay_radius_cells != 1 or config.visual_radius_cells != 3:
		fail("default streaming radii changed")
		return
	if not is_equal_approx(config.predictive_lookahead_seconds, 2.25) or config.unload_hysteresis_cells != 1:
		fail("default predictive/hysteresis contract changed")
		return
	var policy = policy_script.new()
	var stationary: Dictionary = policy.desired_cells(grid, config, Vector3(10, 0, 10), Vector3.ZERO)
	if stationary.gameplay.size() != 9:
		fail("stationary center observer must request 3x3 gameplay cells")
		return
	if stationary.visual.size() != 49:
		fail("stationary center observer must request 7x7 visual cells")
		return
	if not _is_sorted(stationary.gameplay) or not _is_sorted(stationary.visual):
		fail("streaming sets must be deterministically sorted")
		return
	var moving: Dictionary = policy.desired_cells(grid, config, Vector3(10, 0, 10), Vector3(0, 0, -80))
	if Vector2i(0, -1) not in moving.predictive:
		fail("80 m/s forward motion must predict the cell ahead")
		return
	for key in ["gameplay", "predictive", "visual", "keep_resident"]:
		for coord in moving[key]:
			if not grid.is_valid_coord(coord):
				fail("prediction escaped world bounds: %s" % coord)
				return
	var repeat: Dictionary = policy.desired_cells(grid, config, Vector3(10, 0, 10), Vector3(0, 0, -80))
	if repeat != moving:
		fail("streaming policy must be deterministic")
		return
	var residents := {Vector2i(4, 0): true, Vector2i(5, 0): true}
	var hysteresis: Dictionary = policy.desired_cells(grid, config, Vector3(10, 0, 10), Vector3.ZERO, residents)
	if Vector2i(4, 0) not in hysteresis.keep_resident:
		fail("resident cell in one-cell unload band must be retained")
		return
	if Vector2i(5, 0) in hysteresis.keep_resident:
		fail("resident cell beyond hysteresis band must unload")
		return
	var edge: Dictionary = policy.desired_cells(grid, config, Vector3(3000, 0, 3000), Vector3(80, 0, 80))
	for coord in edge.visual + edge.predictive:
		if not grid.is_valid_coord(coord):
			fail("edge prediction must clip to grid")
			return
	print("PASS: phase2 09_streaming_policy")
	quit(0)

func _is_sorted(values: Array) -> bool:
	for i in range(1, values.size()):
		var previous: Vector2i = values[i - 1]
		var current: Vector2i = values[i]
		if current.x < previous.x or (current.x == previous.x and current.y < previous.y):
			return false
	return true
