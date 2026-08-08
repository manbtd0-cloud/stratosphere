class_name TrafficSpawner
extends RefCounted

@export var min_player_distance_m: float = 70.0
@export var max_spawn_distance_m: float = 480.0
@export var close_view_distance_m: float = 220.0
@export var view_cone_dot_threshold: float = 0.35
@export var occupied_clearance_m: float = 14.0
@export var preferred_spawn_distance_m: float = 190.0

func is_candidate_safe(position: Vector3, _lane_forward: Vector3, player_transform: Transform3D, occupied_positions: Array) -> bool:
	var to_candidate := position - player_transform.origin
	var distance := to_candidate.length()
	if distance < min_player_distance_m or distance > max_spawn_distance_m:
		return false
	if distance <= close_view_distance_m and distance > 0.001:
		var view_forward := -player_transform.basis.z.normalized()
		if view_forward.dot(to_candidate / distance) > view_cone_dot_threshold:
			return false
	for occupied in occupied_positions:
		if occupied is Vector3 and position.distance_to(occupied) < occupied_clearance_m:
			return false
	return true

func choose_candidate(graph: TrafficLaneGraph, player_transform: Transform3D, occupied_positions: Array) -> TrafficSpawnCandidate:
	if graph == null:
		return null
	var candidates: Array[Dictionary] = []
	for lane_id in graph.lane_ids():
		var lane := graph.get_lane(lane_id)
		if lane == null or not lane.civilian_enabled:
			continue
		var positions := lane.sampled_positions
		for index in range(0, positions.size(), 3):
			var position := positions[index]
			var forward := _path_forward(positions, index)
			if not is_candidate_safe(position, forward, player_transform, occupied_positions):
				continue
			var distance := position.distance_to(player_transform.origin)
			var candidate := TrafficSpawnCandidate.new()
			candidate.lane_id = lane.id
			candidate.position = position
			candidate.forward = forward
			candidate.sample_index = index
			candidate.distance_to_player_m = distance
			candidate.cell_id = _cell_id_for_sample(lane, index)
			var score := absf(distance - preferred_spawn_distance_m)
			candidates.append({"candidate": candidate, "score": score, "key": candidate.fingerprint()})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a: float = float(a.score)
		var score_b: float = float(b.score)
		if not is_equal_approx(score_a, score_b):
			return score_a < score_b
		return String(a.key) < String(b.key)
	)
	if candidates.is_empty():
		return null
	return candidates[0].candidate as TrafficSpawnCandidate

func _path_forward(positions: PackedVector3Array, index: int) -> Vector3:
	if positions.size() < 2:
		return Vector3.FORWARD
	var a_index := clampi(index, 0, positions.size() - 1)
	var b_index := mini(a_index + 1, positions.size() - 1)
	if b_index == a_index:
		a_index = maxi(0, a_index - 1)
	var forward := positions[b_index] - positions[a_index]
	return forward.normalized() if forward.length_squared() > 0.0001 else Vector3.FORWARD

func _cell_id_for_sample(lane: TrafficLane, sample_index: int) -> StringName:
	if lane.cell_ids.is_empty():
		return &""
	var normalized := float(sample_index) / maxf(float(lane.sampled_positions.size() - 1), 1.0)
	var cell_index := clampi(floori(normalized * float(lane.cell_ids.size())), 0, lane.cell_ids.size() - 1)
	return lane.cell_ids[cell_index]
