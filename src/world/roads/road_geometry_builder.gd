class_name RoadGeometryBuilder
extends RefCounted

const STRIP_ROAD := 0
const STRIP_LEFT_SHOULDER := 1
const STRIP_RIGHT_SHOULDER := 2

var _sampler := RoadSplineSampler.new()

func build_surface_arrays(segment: RoadSegment, profile: RoadProfile) -> Dictionary:
	if segment == null or profile == null:
		return {}
	var samples := _sampler.sample(segment, profile.sample_spacing_m)
	if samples.size() < 2:
		return {}
	return {
		"road": _build_strip(samples, STRIP_ROAD),
		"left_shoulder": _build_strip(samples, STRIP_LEFT_SHOULDER),
		"right_shoulder": _build_strip(samples, STRIP_RIGHT_SHOULDER),
		"sample_count": samples.size(),
	}

func create_segment_node(segment: RoadSegment, profile: RoadProfile) -> Node3D:
	var root := Node3D.new()
	root.name = _node_name(segment.id)
	root.set_meta("road_segment_id", segment.id)
	var surfaces := build_surface_arrays(segment, profile)
	if surfaces.is_empty():
		return root
	_add_mesh(root, "RoadSurface", surfaces["road"])
	_add_mesh(root, "LeftShoulder", surfaces["left_shoulder"])
	_add_mesh(root, "RightShoulder", surfaces["right_shoulder"])
	_add_collision(root, "RoadCollision", surfaces["road"], segment.surface_id)
	_add_collision(root, "LeftShoulderCollision", surfaces["left_shoulder"], profile.shoulder_surface_id)
	_add_collision(root, "RightShoulderCollision", surfaces["right_shoulder"], profile.shoulder_surface_id)
	return root

func _build_strip(samples: Array[RoadSample], strip_kind: int) -> Array:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for sample in samples:
		var offsets := Vector2.ZERO
		match strip_kind:
			STRIP_ROAD:
				offsets = Vector2(-sample.half_road_width_m, sample.half_road_width_m)
			STRIP_LEFT_SHOULDER:
				offsets = Vector2(-sample.half_road_width_m - sample.shoulder_width_m, -sample.half_road_width_m)
			STRIP_RIGHT_SHOULDER:
				offsets = Vector2(sample.half_road_width_m, sample.half_road_width_m + sample.shoulder_width_m)
		vertices.append(sample.position + sample.right * offsets.x)
		vertices.append(sample.position + sample.right * offsets.y)
		normals.append(sample.up)
		normals.append(sample.up)
		uvs.append(Vector2(0.0, sample.accumulated_distance_m * 0.1))
		uvs.append(Vector2(1.0, sample.accumulated_distance_m * 0.1))
	for i in range(samples.size() - 1):
		var base := i * 2
		indices.append_array(PackedInt32Array([
			base, base + 2, base + 1,
			base + 1, base + 2, base + 3,
		]))
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays

func _add_mesh(parent: Node3D, node_name: String, arrays: Array) -> void:
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	parent.add_child(instance)

func _add_collision(parent: Node3D, node_name: String, arrays: Array, surface_id: StringName) -> void:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var faces := PackedVector3Array()
	for index in indices:
		faces.append(vertices[index])
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var body := StaticBody3D.new()
	body.name = node_name
	body.set_meta("surface_id", surface_id)
	body.set_meta("road_collision", true)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)

func _node_name(road_id: StringName) -> String:
	var text := String(road_id).replace(".", "_").replace("-", "_")
	return "Road_%s" % text
