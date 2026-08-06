extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var profile_script := load("res://src/input/input_profile.gd")
	var router_script := load("res://src/input/input_router.gd")
	if profile_script == null or router_script == null:
		fail("input scripts must load")
		return

	var profile = profile_script.new()
	if profile.keyboard_steering_rise <= 0.0:
		fail("keyboard steering rise must be positive")
		return
	if profile.controller_steering_deadzone <= 0.0 or profile.controller_steering_deadzone >= 0.5:
		fail("controller deadzone must be between zero and 0.5")
		return

	profile.controller_steering_deadzone = 4.0
	profile.keyboard_steering_rise = -1.0
	var sanitized = profile.sanitized_copy()
	if not is_equal_approx(sanitized.controller_steering_deadzone, 0.45):
		fail("controller deadzone must clamp to 0.45")
		return
	if not is_equal_approx(sanitized.keyboard_steering_rise, 0.1):
		fail("steering rise must clamp to 0.1")
		return

	var router = router_script.new()
	router.profile = profile_script.new()
	router.sample_keyboard(0.1, 1.0, true, false)
	if router.get_steering() <= 0.0 or router.get_steering() >= 1.0:
		fail("keyboard steering must ramp progressively")
		return
	if router.get_throttle() <= 0.0:
		fail("keyboard throttle must ramp progressively")
		return
	router.sample_keyboard(0.2, 1.0, true, false)
	if not is_equal_approx(router.get_steering(), 1.0):
		fail("keyboard steering must reach full input")
		return

	var actions := PackedStringArray([
		"drive_steer_left", "drive_steer_right", "drive_throttle", "drive_brake",
		"drive_handbrake", "drive_shift_up", "drive_shift_down", "drive_reset",
		"camera_next", "pause"
	])
	for action in actions:
		if not InputMap.has_action(action):
			fail("missing input action: %s" % action)
			return

	router.free()
	print("PASS: input profile contract")
	quit(0)
