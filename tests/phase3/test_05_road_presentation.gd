extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var builder_script = load("res://src/world/roads/presentation/road_presentation_builder.gd")
	if builder_script == null:
		fail("RoadPresentationBuilder script must exist")
		return
	var builder = builder_script.new()
	var expectations := {
		&"highway": {"markings": true, "delineators": true, "guardrails": false, "chevrons": false},
		&"rural_two_lane": {"markings": true, "delineators": true, "guardrails": false, "chevrons": false},
		&"hill_two_lane": {"markings": true, "delineators": true, "guardrails": true, "chevrons": true},
		&"service": {"markings": true, "delineators": false, "guardrails": false, "chevrons": false},
		&"dirt_trail": {"markings": false, "delineators": false, "guardrails": false, "chevrons": false},
	}
	for profile_id in expectations:
		var segment := _segment(profile_id)
		var profile := RoadProfile.for_id(profile_id)
		var presentation: Node3D = builder.build_segment_presentation(segment, profile)
		if presentation == null:
			fail("presentation builder returned null for %s" % profile_id)
			return
		if presentation.get_meta("road_segment_id", &"") != segment.id:
			fail("presentation must retain authoritative source road ID")
			presentation.free(); return
		var expected: Dictionary = expectations[profile_id]
		for key in ["markings", "delineators", "guardrails", "chevrons"]:
			var count := int(presentation.get_meta("%s_count" % key, 0))
			if bool(expected[key]) != (count > 0):
				fail("%s policy mismatch for %s: %d" % [key, profile_id, count])
				presentation.free(); return
		if _tree_has_surface_authority(presentation):
			fail("road presentation must never own physics surface_id metadata")
			presentation.free(); return
		presentation.free()
	print("PASS: phase3 05_road_presentation")
	quit(0)

func _segment(profile_id: StringName) -> RoadSegment:
	var segment := RoadSegment.new()
	segment.id = StringName("road.presentation.%s" % profile_id)
	segment.start_junction_id = &"junction.presentation.start"
	segment.end_junction_id = &"junction.presentation.end"
	segment.profile_id = profile_id
	segment.surface_id = &"dirt" if profile_id == &"dirt_trail" else &"asphalt_dry"
	segment.centerline = Curve3D.new()
	segment.centerline.add_point(Vector3(0, 0, 0))
	segment.centerline.add_point(Vector3(80, 0, -120), Vector3(-20, 0, 10), Vector3(20, 0, -10))
	segment.centerline.add_point(Vector3(160, 8 if profile_id == &"hill_two_lane" else 0, -240))
	return segment

func _tree_has_surface_authority(node: Node) -> bool:
	if node.has_meta("surface_id"):
		return true
	for child in node.get_children():
		if _tree_has_surface_authority(child):
			return true
	return false
