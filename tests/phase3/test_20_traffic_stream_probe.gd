extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var probe_script = load("res://src/world/validation/driving_world_probe.gd")
	if probe_script == null:
		fail("DrivingWorldProbe script must exist")
		return
	var first: Dictionary = probe_script.new().run()
	var second: Dictionary = probe_script.new().run()
	if first.is_empty() or second.is_empty(): fail("Phase 3 logical probe must return evidence"); return
	if first.checksum != second.checksum: fail("Phase 3 probe checksum must be deterministic"); return
	if int(first.authored_cells) != 20: fail("probe must cover 20 authored cells (~5.24 km2)"); return
	if int(first.route_steps) < 8 or int(first.predictive_steps) <= 0: fail("probe must exercise a representative predictive-driving route"); return
	if int(first.max_gameplay_cells) > 9 or int(first.max_visual_cells) > 49 or int(first.max_predictive_cells) > 9:
		fail("Phase 3 probe exceeded Phase 2 streaming bounds"); return
	if int(first.traffic_candidates) < 8 or int(first.traffic_candidates) > 20 or bool(first.duplicate_traffic_candidates):
		fail("Phase 3 traffic probe must produce a bounded unique logical population"); return
	if int(first.navigation_edges) <= 0 or int(first.navigation_route_edges) <= 0:
		fail("Phase 3 probe must exercise routable navigation") ; return
	print("PASS: phase3 20_traffic_stream_probe")
	quit(0)
