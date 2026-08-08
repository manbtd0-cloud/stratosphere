extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var resolver_script = load("res://src/surface/surface_resolver.gd")
	if resolver_script == null:
		fail("SurfaceResolver script must exist")
		return
	var collider := StaticBody3D.new()
	collider.set_meta("surface_id", &"gravel")
	if resolver_script.surface_id_from_collider(collider) != &"gravel":
		fail("known collider surface metadata must pass through")
		collider.free()
		return
	collider.remove_meta("surface_id")
	if resolver_script.surface_id_from_collider(collider, &"dirt") != &"dirt":
		fail("missing metadata must return explicit fallback")
		collider.free()
		return
	collider.set_meta("surface_id", &"lava")
	if resolver_script.surface_id_from_collider(collider, &"grass") != &"grass":
		fail("unknown metadata must return explicit fallback")
		collider.free()
		return
	collider.free()
	for surface_id in [&"asphalt_dry", &"asphalt_wet", &"gravel", &"dirt", &"grass"]:
		if not resolver_script.is_supported_id(surface_id):
			fail("Phase 1 surface must remain supported: %s" % surface_id)
			return
	if resolver_script.is_supported_id(&"air"):
		fail("air is not a physical road/terrain surface")
		return
	print("PASS: phase2 07_surface_resolver")
	quit(0)
