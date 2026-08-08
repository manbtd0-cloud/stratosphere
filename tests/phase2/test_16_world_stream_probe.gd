extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var probe_script = load("res://tools/benchmark/run_world_stream_probe.gd")
	if probe_script == null:
		fail("world stream probe script must exist")
		return
	var definition := ProvingRegionFactory.create()
	var first: Dictionary = probe_script.simulate(definition)
	var second: Dictionary = probe_script.simulate(definition)
	if first.is_empty():
		fail("stream probe must return measured logical results")
		return
	if int(first.get("max_gameplay_cells", 0)) > 9 or int(first.get("max_gameplay_cells", 0)) <= 0:
		fail("gameplay cell count exceeded bounded 3x3 policy")
		return
	if int(first.get("max_visual_cells", 0)) > 49 or int(first.get("max_visual_cells", 0)) <= 0:
		fail("visual cell count exceeded bounded 7x7 policy")
		return
	if int(first.get("predictive_forward_steps", 0)) <= 0:
		fail("high-speed route must exercise predictive loading ahead")
		return
	if int(first.get("route_steps", 0)) < 8:
		fail("stream probe route is too small to exercise the grid")
		return
	if String(first.get("checksum", "")).is_empty() or first.get("checksum") != second.get("checksum"):
		fail("stream probe checksum must be deterministic")
		return
	if first != second:
		fail("repeat stream probe must return identical metrics")
		return
	print("PASS: phase2 16_world_stream_probe")
	quit(0)
