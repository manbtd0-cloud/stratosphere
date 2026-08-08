extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var sample_script = load("res://src/world/roads/road_sample.gd")
	var sampler_script = load("res://src/world/roads/road_spline_sampler.gd")
	if sample_script == null or sampler_script == null:
		fail("road spline sampler scripts must exist")
		return
	var segment := RoadSegment.new()
	segment.id = &"road.sample"
	segment.start_junction_id = &"junction.a"
	segment.end_junction_id = &"junction.b"
	segment.profile_id = &"rural_two_lane"
	segment.centerline = Curve3D.new()
	segment.centerline.add_point(Vector3(0, 2, 0))
	segment.centerline.add_point(Vector3(20, 4, -60), Vector3(-8, 0, 0), Vector3(8, 0, -4))
	segment.centerline.add_point(Vector3(80, 10, -120), Vector3(-12, -2, 2), Vector3.ZERO)
	var sampler = sampler_script.new()
	var samples: Array = sampler.sample(segment, 7.5)
	if samples.size() < 3:
		fail("curved segment must produce multiple samples")
		return
	if samples[0].position.distance_to(segment.centerline.get_point_position(0)) > 0.001:
		fail("first curve endpoint must be included")
		return
	var last_position: Vector3 = segment.centerline.get_point_position(segment.centerline.point_count - 1)
	if samples[-1].position.distance_to(last_position) > 0.001:
		fail("last curve endpoint must be included")
		return
	var previous_distance := -0.001
	for sample in samples:
		if sample.accumulated_distance_m <= previous_distance:
			fail("accumulated distance must increase monotonically")
			return
		previous_distance = sample.accumulated_distance_m
		if absf(sample.forward.length() - 1.0) > 0.001 or absf(sample.up.length() - 1.0) > 0.001 or absf(sample.right.length() - 1.0) > 0.001:
			fail("sample frame vectors must be normalized")
			return
		if absf(sample.forward.dot(sample.up)) > 0.001 or absf(sample.forward.dot(sample.right)) > 0.001:
			fail("sample frame vectors must be orthogonal")
			return
		if sample.forward.cross(sample.up).dot(sample.right) < 0.999:
			fail("sample frame handedness must be consistent")
			return
	for i in range(1, samples.size() - 1):
		var spacing: float = float(samples[i].accumulated_distance_m) - float(samples[i - 1].accumulated_distance_m)
		if spacing > 7.51:
			fail("interior sample spacing exceeded requested bound")
			return
	var repeat: Array = sampler.sample(segment, 7.5)
	if repeat.size() != samples.size():
		fail("sampling must be deterministic")
		return
	for i in samples.size():
		if samples[i].position.distance_to(repeat[i].position) > 0.00001:
			fail("repeat sampling changed sample position")
			return
	print("PASS: phase2 05_road_spline_sampler")
	quit(0)
