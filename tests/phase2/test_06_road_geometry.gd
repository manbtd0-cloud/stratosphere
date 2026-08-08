extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var builder_script = load("res://src/world/roads/road_geometry_builder.gd")
	if builder_script == null:
		fail("RoadGeometryBuilder script must exist")
		return
	var builder = builder_script.new()
	var profile := RoadProfile.for_id(&"rural_two_lane")
	var first := _make_segment(&"road.first", Vector3(0, 0, 0), Vector3(0, 0, -80))
	var arrays: Dictionary = builder.build_surface_arrays(first, profile)
	if not arrays.has("road") or not arrays.has("left_shoulder") or not arrays.has("right_shoulder"):
		fail("geometry arrays must include road and both shoulders")
		return
	var road: Array = arrays["road"]
	var vertices: PackedVector3Array = road[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = road[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = road[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = road[Mesh.ARRAY_INDEX]
	if vertices.size() < 4 or vertices.size() % 2 != 0:
		fail("road strip must contain paired vertices")
		return
	if normals.size() != vertices.size() or uvs.size() != vertices.size():
		fail("road normals and UVs must match vertex count")
		return
	if indices.size() != (vertices.size() / 2 - 1) * 6:
		fail("road strip index count must be deterministic")
		return
	for vertex in vertices:
		if not vertex.is_finite():
			fail("road vertices must be finite")
			return
	var width := vertices[0].distance_to(vertices[1])
	if absf(width - profile.road_width_m()) > 0.02:
		fail("generated road width differs from profile")
		return
	var left_vertices: PackedVector3Array = (arrays["left_shoulder"] as Array)[Mesh.ARRAY_VERTEX]
	var right_vertices: PackedVector3Array = (arrays["right_shoulder"] as Array)[Mesh.ARRAY_VERTEX]
	if left_vertices[0].distance_to(vertices[0]) <= 0.01 or right_vertices[1].distance_to(vertices[1]) <= 0.01:
		fail("shoulder outer vertices must extend outside road")
		return
	var node: Node3D = builder.create_segment_node(first, profile)
	var road_collision := node.get_node_or_null("RoadCollision") as StaticBody3D
	var left_collision := node.get_node_or_null("LeftShoulderCollision") as StaticBody3D
	if road_collision == null or left_collision == null or road_collision.get_node_or_null("CollisionShape3D") == null:
		fail("road and shoulder collision bodies must exist")
		node.free()
		return
	if road_collision.get_meta("surface_id", &"") != first.surface_id:
		fail("road collider must publish segment surface_id")
		node.free()
		return
	if left_collision.get_meta("surface_id", &"") != profile.shoulder_surface_id:
		fail("shoulder collider must publish profile shoulder surface")
		node.free()
		return
	node.free()
	var second := _make_segment(&"road.second", Vector3(0, 0, -80), Vector3(30, 1, -140))
	var first_arrays: Array = builder.build_surface_arrays(first, profile)["road"]
	var second_arrays: Array = builder.build_surface_arrays(second, profile)["road"]
	var fv: PackedVector3Array = first_arrays[Mesh.ARRAY_VERTEX]
	var sv: PackedVector3Array = second_arrays[Mesh.ARRAY_VERTEX]
	var end_center := (fv[-2] + fv[-1]) * 0.5
	var start_center := (sv[0] + sv[1]) * 0.5
	if end_center.distance_to(start_center) >= 0.05:
		fail("segments sharing a junction must not create a centerline seam")
		return
	print("PASS: phase2 06_road_geometry")
	quit(0)

func _make_segment(id: StringName, start: Vector3, finish: Vector3) -> RoadSegment:
	var segment := RoadSegment.new()
	segment.id = id
	segment.start_junction_id = StringName(String(id) + ".start")
	segment.end_junction_id = StringName(String(id) + ".end")
	segment.profile_id = &"rural_two_lane"
	segment.surface_id = &"asphalt_dry"
	segment.centerline = Curve3D.new()
	segment.centerline.add_point(start)
	segment.centerline.add_point(finish)
	return segment
