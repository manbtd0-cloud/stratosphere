extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var service_script := load("res://src/graphics/graphics_quality_service.gd")
	if service_script == null:
		fail("graphics quality service script must load")
		return
	var service = service_script.new()
	var profile = service.load_profile(&"medium")
	if profile == null:
		fail("medium profile must load")
		return
	if service.load_profile(&"does_not_exist") != null:
		fail("unknown profile must return null")
		return
	var viewport := SubViewport.new()
	var errors: PackedStringArray = service.apply_profile(profile, viewport)
	if not errors.is_empty():
		fail("medium profile must apply without errors: %s" % errors)
		return
	if not is_equal_approx(viewport.scaling_3d_scale, profile.render_scale):
		fail("viewport render scale must match profile")
		return
	if not is_equal_approx(viewport.mesh_lod_threshold, profile.mesh_lod_threshold):
		fail("viewport LOD threshold must match profile")
		return
	viewport.free()
	service.free()
	print("PASS: graphics quality service contract")
	quit(0)
