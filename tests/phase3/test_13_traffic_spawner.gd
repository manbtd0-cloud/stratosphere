extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var spawner_script = load("res://src/traffic/traffic_spawner.gd")
	if spawner_script == null:
		fail("TrafficSpawner script must exist")
		return
	var spawner = spawner_script.new()
	var player := Transform3D(Basis.IDENTITY, Vector3.ZERO)
	if spawner.is_candidate_safe(Vector3(0,0,-100), Vector3.FORWARD, player, []):
		fail("close candidate in player's forward view cone must reject")
		return
	if spawner.is_candidate_safe(Vector3(0,0,40), Vector3.BACK, player, []):
		fail("candidate below minimum player distance must reject")
		return
	if spawner.is_candidate_safe(Vector3(0,0,180), Vector3.BACK, player, [Vector3(0,0,181)]):
		fail("candidate overlapping occupied lane space must reject")
		return
	if not spawner.is_candidate_safe(Vector3(120,0,160), Vector3.BACK, player, []):
		fail("valid side/behind candidate should be accepted")
		return
	var region := DrivingRegionFactory.create()
	var graph := TrafficLaneGraphBuilder.new().build(region.base_definition.road_network, region.base_definition.grid)
	var candidate = spawner.choose_candidate(graph, player, [])
	if candidate == null or candidate.lane_id.is_empty() or candidate.position.distance_to(player.origin) < spawner.min_player_distance_m:
		fail("spawner must choose a safe deterministic lane candidate")
		return
	var repeat = spawner.choose_candidate(graph, player, [])
	if repeat == null or repeat.fingerprint() != candidate.fingerprint():
		fail("spawn candidate choice must be deterministic")
		return
	print("PASS: phase3 13_traffic_spawner")
	quit(0)
