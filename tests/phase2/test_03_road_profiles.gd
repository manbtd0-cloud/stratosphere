extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var profile_script = load("res://src/world/roads/road_profile.gd")
	if profile_script == null:
		fail("RoadProfile script must exist")
		return
	var expected := {
		&"highway": &"asphalt_dry",
		&"rural_two_lane": &"asphalt_dry",
		&"hill_two_lane": &"asphalt_dry",
		&"service": &"asphalt_dry",
		&"dirt_trail": &"dirt",
	}
	for profile_id in expected:
		var profile = profile_script.for_id(profile_id)
		if profile == null:
			fail("missing road profile: %s" % profile_id)
			return
		if profile.id != profile_id:
			fail("profile ID mismatch: %s" % profile_id)
			return
		if profile.lane_width_m <= 0.0 or profile.lane_count <= 0:
			fail("road dimensions must be positive: %s" % profile_id)
			return
		if profile.sample_spacing_m <= 0.0 or profile.coarse_lod_spacing_m < profile.sample_spacing_m:
			fail("sample spacing contract invalid: %s" % profile_id)
			return
		if profile.base_surface_id != expected[profile_id]:
			fail("unexpected base surface for %s" % profile_id)
			return
		var errors: PackedStringArray = profile.validation_errors()
		if not errors.is_empty():
			fail("valid profile rejected: %s -> %s" % [profile_id, errors])
			return
	if profile_script.for_id(&"unknown") != null:
		fail("unknown road profiles must reject")
		return
	var invalid = profile_script.new()
	invalid.id = &"broken"
	invalid.lane_width_m = 0.0
	if invalid.validation_errors().is_empty():
		fail("invalid dimensions must fail validation")
		return
	print("PASS: phase2 03_road_profiles")
	quit(0)
