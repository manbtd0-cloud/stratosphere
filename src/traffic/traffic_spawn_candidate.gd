class_name TrafficSpawnCandidate
extends RefCounted

var lane_id: StringName = &""
var position: Vector3 = Vector3.ZERO
var forward: Vector3 = Vector3.FORWARD
var cell_id: StringName = &""
var sample_index: int = 0
var distance_to_player_m: float = 0.0

func fingerprint() -> String:
	return "%s|%d|%.3f,%.3f,%.3f|%s" % [lane_id, sample_index, position.x, position.y, position.z, cell_id]
