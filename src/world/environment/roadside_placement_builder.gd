class_name RoadsidePlacementBuilder
extends RefCounted

var _sampler := RoadSplineSampler.new()

func build_side_anchors(
	segment: RoadSegment,
	profile: RoadProfile,
	spacing_m: float,
	lateral_offset_m: float,
	both_sides: bool = true,
	start_margin_m: float = 8.0,
	end_margin_m: float = 8.0
) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	if segment == null or profile == null or spacing_m <= 0.0:
		return result
	var samples := _sampler.sample(segment, spacing_m)
	if samples.is_empty():
		return result
	var total: float = samples[-1].accumulated_distance_m
	for sample in samples:
		if sample.accumulated_distance_m < start_margin_m or sample.accumulated_distance_m > total - end_margin_m:
			continue
		var basis := Basis(sample.right, sample.up, -sample.forward).orthonormalized()
		var right_position := sample.position + sample.right * lateral_offset_m
		result.append(Transform3D(basis, right_position))
		if both_sides:
			var left_basis := Basis(-sample.right, sample.up, sample.forward).orthonormalized()
			var left_position := sample.position - sample.right * lateral_offset_m
			result.append(Transform3D(left_basis, left_position))
	return result

func build_centerline_anchors(segment: RoadSegment, spacing_m: float) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	if segment == null or spacing_m <= 0.0:
		return result
	for sample in _sampler.sample(segment, spacing_m):
		var basis := Basis(sample.right, sample.up, -sample.forward).orthonormalized()
		result.append(Transform3D(basis, sample.position + sample.up * 0.025))
	return result
