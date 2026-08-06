extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var settings_script := load("res://src/settings/game_settings.gd")
	var service_script := load("res://src/settings/settings_service.gd")
	if settings_script == null or service_script == null:
		fail("settings scripts must load")
		return

	var settings = settings_script.new()
	if settings.resolution_width != 1280 or settings.resolution_height != 720:
		fail("default resolution must be 1280x720")
		return
	if settings.graphics_profile != &"medium":
		fail("default graphics profile must be medium")
		return
	if not is_equal_approx(settings.traffic_density, 1.0):
		fail("default traffic density must be 1.0")
		return

	settings.master_volume = 4.0
	settings.camera_fov = 200.0
	settings.traffic_density = -3.0
	var sanitized = settings.sanitized_copy()
	if not is_equal_approx(sanitized.master_volume, 1.0):
		fail("master volume must clamp to 1.0")
		return
	if not is_equal_approx(sanitized.camera_fov, 110.0):
		fail("camera FOV must clamp to 110")
		return
	if not is_equal_approx(sanitized.traffic_density, 0.0):
		fail("traffic density must clamp to zero")
		return

	var test_path := "user://phase0-tests/settings.json"
	var service = service_script.new(test_path)
	service.delete_settings()
	sanitized.graphics_profile = &"high"
	if service.save_settings(sanitized) != OK:
		fail("settings must save successfully")
		return
	var loaded = service.load_settings()
	if loaded.graphics_profile != &"high":
		fail("graphics profile must round-trip")
		return
	if not is_equal_approx(loaded.camera_fov, 110.0):
		fail("camera FOV must round-trip")
		return

	service.free()
	settings = null
	sanitized = null
	loaded = null
	settings_script = null
	service_script = null
	print("PASS: game settings contract")
	quit(0)
