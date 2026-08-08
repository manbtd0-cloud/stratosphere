class_name RoadSplineSampler
extends RefCounted

func sample(segment: RoadSegment, spacing_m: float = -1.0) -> Array[RoadSample]:
	var result: Array[RoadSample] = []
	if segment == null or segment.centerline == null or segment.centerline.point_count < 2:
		return result
	var profile := RoadProfile.for_id(segment.profile_id)
	if profile == null:
		return result
	var spacing := spacing_m if spacing_m > 0.0 else profile.sample_spacing_m
	spacing = maxf(spacing, 0.1)
	var curve := segment.centerline
	var length := curve.get_baked_length()
	if length <= 0.0001:
		return result
	var distances: Array[float] = []
	var distance := 0.0
	while distance < length:
		distances.append(distance)
		distance += spacing
	if distances.is_empty() or not is_equal_approx(distances[-1], length):
		distances.append(length)
	var half_width := profile.road_width_m() * 0.5
	var shoulder := segment.shoulder_width_override_m if segment.shoulder_width_override_m >= 0.0 else profile.shoulder_width_m
	var bank := deg_to_rad(segment.banking_degrees)
	for baked_distance in distances:
		var road_sample := RoadSample.new()
		road_sample.position = curve.sample_baked(baked_distance, true)
		road_sample.accumulated_distance_m = baked_distance
		road_sample.half_road_width_m = half_width
		road_sample.shoulder_width_m = shoulder
		road_sample.banking_radians = bank
		var epsilon := minf(maxf(spacing * 0.2, 0.05), maxf(length * 0.25, 0.05))
		var before_distance := maxf(0.0, baked_distance - epsilon)
		var after_distance := minf(length, baked_distance + epsilon)
		var before := curve.sample_baked(before_distance, true)
		var after := curve.sample_baked(after_distance, true)
		var tangent := after - before
		if tangent.length_squared() < 0.000001:
			tangent = Vector3.FORWARD
		road_sample.forward = tangent.normalized()
		var base_up := Vector3.UP
		if absf(road_sample.forward.dot(base_up)) > 0.98:
			base_up = Vector3.FORWARD
		var base_right := road_sample.forward.cross(base_up).normalized()
		var banked_right := base_right.rotated(road_sample.forward, bank).normalized()
		var banked_up := banked_right.cross(road_sample.forward).normalized()
		road_sample.right = banked_right
		road_sample.up = banked_up
		result.append(road_sample)
	return result
