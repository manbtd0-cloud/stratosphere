class_name RoadPresentationBuilder
extends RefCounted

var _sampler := RoadSplineSampler.new()
var _placement := RoadsidePlacementBuilder.new()

func build_segment_presentation(segment: RoadSegment, profile: RoadProfile) -> Node3D:
	if segment == null or profile == null:
		return null
	var root := Node3D.new()
	root.name = "RoadPresentation_%s" % String(segment.id).replace(".", "_")
	root.set_meta("road_segment_id", segment.id)
	root.set_meta("road_profile_id", profile.id)
	var marking_transforms := _marking_transforms(segment, profile)
	var delineator_transforms: Array[Transform3D] = []
	var guardrail_transforms: Array[Transform3D] = []
	var chevron_transforms: Array[Transform3D] = []
	if profile.id in [&"highway", &"rural_two_lane", &"hill_two_lane"]:
		delineator_transforms = _placement.build_side_anchors(segment, profile, 42.0, profile.road_width_m() * 0.5 + profile.shoulder_width_m + 0.65)
	if profile.id == &"hill_two_lane":
		guardrail_transforms = _placement.build_side_anchors(segment, profile, 7.0, profile.road_width_m() * 0.5 + profile.shoulder_width_m + 0.35)
		chevron_transforms = _placement.build_side_anchors(segment, profile, 28.0, profile.road_width_m() * 0.5 + profile.shoulder_width_m + 1.15, false)
	_add_markings(root, marking_transforms)
	_add_delineators(root, delineator_transforms)
	_add_guardrails(root, guardrail_transforms)
	_add_chevrons(root, chevron_transforms)
	root.set_meta("markings_count", marking_transforms.size())
	root.set_meta("delineators_count", delineator_transforms.size())
	root.set_meta("guardrails_count", guardrail_transforms.size())
	root.set_meta("chevrons_count", chevron_transforms.size())
	return root

func _marking_transforms(segment: RoadSegment, profile: RoadProfile) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	if profile.marking_policy == &"none":
		return result
	var samples := _sampler.sample(segment, 6.0)
	if samples.is_empty():
		return result
	for sample in samples:
		var basis := Basis(sample.right, sample.up, -sample.forward).orthonormalized()
		var offsets: Array[float] = []
		match profile.marking_policy:
			&"highway":
				for lane_index in range(1, profile.lane_count):
					offsets.append(-profile.road_width_m() * 0.5 + float(lane_index) * profile.lane_width_m)
				offsets.append(-profile.road_width_m() * 0.5 + 0.15)
				offsets.append(profile.road_width_m() * 0.5 - 0.15)
			&"center_and_edge":
				offsets.assign([0.0, -profile.road_width_m() * 0.5 + 0.12, profile.road_width_m() * 0.5 - 0.12])
			&"center":
				offsets.append(0.0)
		for offset in offsets:
			result.append(Transform3D(basis, sample.position + sample.right * offset + sample.up * 0.035))
	return result

func _add_markings(parent: Node3D, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.11, 0.018, 3.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.91, 0.91, 0.84)
	material.roughness = 0.78
	mesh.material = material
	parent.add_child(_multimesh_node("Markings", mesh, transforms))

func _add_delineators(parent: Node3D, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.10, 0.95, 0.10)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.86, 0.86, 0.82)
	material.roughness = 0.72
	mesh.material = material
	var lifted := _translated(transforms, Vector3.UP * 0.475)
	parent.add_child(_multimesh_node("Delineators", mesh, lifted))

func _add_guardrails(parent: Node3D, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.42, 6.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.47, 0.49, 0.50)
	material.metallic = 0.7
	material.roughness = 0.52
	mesh.material = material
	var lifted := _translated(transforms, Vector3.UP * 0.65)
	parent.add_child(_multimesh_node("Guardrails", mesh, lifted))

func _add_chevrons(parent: Node3D, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.82, 0.62, 0.05)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.85, 0.14)
	material.roughness = 0.65
	mesh.material = material
	var lifted := _translated(transforms, Vector3.UP * 1.15)
	parent.add_child(_multimesh_node("Chevrons", mesh, lifted))

func _multimesh_node(node_name: String, mesh: Mesh, transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	return instance

func _translated(transforms: Array[Transform3D], world_offset: Vector3) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for transform in transforms:
		var adjusted := transform
		adjusted.origin += world_offset
		result.append(adjusted)
	return result
