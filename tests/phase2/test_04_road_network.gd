extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var junction_script = load("res://src/world/roads/road_junction.gd")
	var segment_script = load("res://src/world/roads/road_segment.gd")
	var network_script = load("res://src/world/roads/road_network.gd")
	if junction_script == null or segment_script == null or network_script == null:
		fail("road graph scripts must exist")
		return
	var network = network_script.new()
	var a = junction_script.new()
	a.id = &"junction.a"
	a.position = Vector3(0, 0, 0)
	var b = junction_script.new()
	b.id = &"junction.b"
	b.position = Vector3(0, 0, -120)
	if network.add_junction(a) != OK or network.add_junction(b) != OK:
		fail("valid junctions must register")
		return
	if network.add_junction(a) != ERR_ALREADY_EXISTS:
		fail("duplicate junction IDs must reject")
		return
	var segment = segment_script.new()
	segment.id = &"road.ab"
	segment.start_junction_id = a.id
	segment.end_junction_id = b.id
	segment.profile_id = &"rural_two_lane"
	segment.surface_id = &"asphalt_dry"
	segment.centerline = Curve3D.new()
	segment.centerline.add_point(a.position)
	segment.centerline.add_point(b.position)
	if network.add_segment(segment) != OK:
		fail("valid segment must register")
		return
	if network.add_segment(segment) != ERR_ALREADY_EXISTS:
		fail("duplicate road IDs must reject")
		return
	if network.connected_segments(a.id).size() != 1 or network.connected_segments(b.id).size() != 1:
		fail("connected segment lookup must include both endpoints")
		return
	var missing = segment_script.new()
	missing.id = &"road.missing_endpoint"
	missing.start_junction_id = a.id
	missing.end_junction_id = &"junction.nope"
	missing.profile_id = &"service"
	missing.centerline = Curve3D.new()
	missing.centerline.add_point(Vector3.ZERO)
	missing.centerline.add_point(Vector3(20, 0, 0))
	if network.add_segment(missing) != ERR_DOES_NOT_EXIST:
		fail("segments with missing endpoint junctions must reject")
		return
	var malformed = segment_script.new()
	malformed.id = &"road.malformed"
	malformed.start_junction_id = a.id
	malformed.end_junction_id = b.id
	malformed.profile_id = &"service"
	malformed.centerline = Curve3D.new()
	malformed.centerline.add_point(Vector3.ZERO)
	if network.add_segment(malformed) != ERR_INVALID_DATA:
		fail("segment curve requires at least two control points")
		return
	var rogue = junction_script.new()
	rogue.id = &"junction.rogue"
	rogue.position = Vector3(50, 0, 50)
	rogue.connected_road_ids.assign([&"road.ghost"])
	if network.add_junction(rogue) != OK:
		fail("junction with declared future connection should register")
		return
	var errors: PackedStringArray = network.validation_errors()
	if not _contains_fragment(errors, "road.ghost"):
		fail("network validation must reject disconnected declared road IDs")
		return
	print("PASS: phase2 04_road_network")
	quit(0)

func _contains_fragment(values: PackedStringArray, fragment: String) -> bool:
	for value in values:
		if fragment in value:
			return true
	return false
