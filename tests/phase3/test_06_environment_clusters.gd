extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var builder_script = load("res://src/world/environment/environment_cluster_builder.gd")
	if builder_script == null:
		fail("EnvironmentClusterBuilder script must exist")
		return
	var transforms: Array[Transform3D] = []
	for i in range(20):
		transforms.append(Transform3D(Basis.IDENTITY, Vector3(float(i * 7), 0.0, float((i % 4) * 9))))
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, 4.0, 1.0)
	var builder = builder_script.new()
	var first: MultiMeshInstance3D = builder.build_cluster(&"forest.test", &"world.proving.cp00_p00", mesh, transforms, 0.5)
	if first == null or first.multimesh == null:
		fail("cluster builder must return a MultiMeshInstance3D")
		return
	if first.multimesh.instance_count != 10:
		fail("quality density 0.5 must deterministically select 10/20 instances")
		first.free(); return
	if first.get_meta("cluster_id", &"") != &"forest.test" or first.get_meta("cell_id", &"") != &"world.proving.cp00_p00":
		fail("cluster must retain stable cluster/cell ownership metadata")
		first.free(); return
	var ids: PackedStringArray = first.get_meta("instance_ids", PackedStringArray())
	if ids.size() != 10 or _has_duplicates(ids):
		fail("cluster must publish unique stable instance IDs")
		first.free(); return
	var fingerprint := String(first.get_meta("transform_fingerprint", ""))
	var repeat: MultiMeshInstance3D = builder.build_cluster(&"forest.test", &"world.proving.cp00_p00", mesh, transforms, 0.5)
	if repeat.multimesh.instance_count != first.multimesh.instance_count or String(repeat.get_meta("transform_fingerprint", "")) != fingerprint:
		fail("rebuilding a deterministic cluster must reproduce transforms")
		first.free(); repeat.free(); return
	first.free(); repeat.free()
	print("PASS: phase3 06_environment_clusters")
	quit(0)

func _has_duplicates(values: PackedStringArray) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value):
			return true
		seen[value] = true
	return false
