extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var policy_script = load("res://src/traffic/traffic_simulation_policy.gd")
	if policy_script == null:
		fail("TrafficSimulationPolicy script must exist")
		return
	var policy = policy_script.new()
	if policy.level_for(&"traffic.a", 50.0) != &"near": fail("50m traffic must be near"); return
	if policy.level_for(&"traffic.a", 250.0) != &"mid": fail("250m traffic must be mid"); return
	if policy.level_for(&"traffic.a", 700.0) != &"far": fail("700m traffic must be far"); return
	if policy.level_for(&"traffic.a", 130.0, &"near") != &"near": fail("near hysteresis must retain agent at 130m"); return
	if policy.level_for(&"traffic.a", 130.0) != &"mid": fail("fresh 130m agent should enter mid, not near"); return
	if policy.level_for(&"traffic.a", 470.0, &"mid") != &"mid": fail("mid hysteresis must retain agent at 470m"); return
	if policy.level_for(&"traffic.a", 470.0) != &"far": fail("fresh 470m agent should enter far"); return
	for distance in [0.0, 100.0, 1000.0]:
		if policy.level_for(&"player", distance, &"far") != &"player": fail("player must never enter traffic simulation LOD"); return
	if not policy.validation_errors().is_empty(): fail("default simulation policy must validate"); return
	print("PASS: phase3 11_traffic_simulation_policy")
	quit(0)
