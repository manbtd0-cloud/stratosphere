extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var profile_script := load("res://src/graphics/render_quality_profile.gd")
	if profile_script == null:
		fail("render quality profile script must load")
		return

	var invalid = profile_script.new()
	invalid.profile_id = &"invalid"
	invalid.render_scale = 5.0
	invalid.mesh_lod_threshold = -2.0
	invalid.vegetation_density = 4.0
	var sanitized = invalid.sanitized_copy()
	if not is_equal_approx(sanitized.render_scale, 1.5):
		fail("render scale must clamp to 1.5")
		return
	if not is_equal_approx(sanitized.mesh_lod_threshold, 0.1):
		fail("LOD threshold must clamp to 0.1")
		return
	if not is_equal_approx(sanitized.vegetation_density, 2.0):
		fail("vegetation density must clamp to 2.0")
		return

	var ids := PackedStringArray(["low", "medium", "high", "ultra", "cinematic"])
	var previous_scale := 0.0
	var previous_density := 0.0
	for id in ids:
		var resource_path := "res://data/graphics/%s.tres" % id
		var profile = load(resource_path)
		if profile == null:
			fail("profile must load: %s" % resource_path)
			return
		if profile.profile_id != StringName(id):
			fail("profile ID must match filename: %s" % id)
			return
		if profile.render_scale < previous_scale:
			fail("render scales must not decrease across quality tiers")
			return
		if profile.vegetation_density < previous_density:
			fail("vegetation density must not decrease across quality tiers")
			return
		previous_scale = profile.render_scale
		previous_density = profile.vegetation_density

	print("PASS: render quality profile contract")
	quit(0)
