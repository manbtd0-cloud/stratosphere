extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)

func has_motion(action: StringName, axis: JoyAxis, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, axis_value):
			return true
	return false

func has_button(action: StringName, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false

func _init() -> void:
	var router := InputRouter.new()
	if not has_motion(&"drive_steer_left", JOY_AXIS_LEFT_X, -1.0) or not has_motion(&"drive_steer_right", JOY_AXIS_LEFT_X, 1.0):
		fail("left stick must be bound to steering")
		return
	if not has_motion(&"drive_throttle", JOY_AXIS_TRIGGER_RIGHT, 1.0) or not has_motion(&"drive_brake", JOY_AXIS_TRIGGER_LEFT, 1.0):
		fail("controller triggers must be bound to throttle and brake")
		return
	for requirement in [[&"drive_handbrake", JOY_BUTTON_A], [&"drive_clutch", JOY_BUTTON_X], [&"camera_next", JOY_BUTTON_Y], [&"drive_shift_down", JOY_BUTTON_LEFT_SHOULDER], [&"drive_shift_up", JOY_BUTTON_RIGHT_SHOULDER]]:
		if not has_button(requirement[0], requirement[1]):
			fail("missing controller button binding for %s" % requirement[0])
			return
	router.profile.controller_steering_deadzone = 0.12
	router.sample_analog(1.0 / 60.0, 0.08, 0.45, 0.35)
	if absf(router.get_steering()) > 0.001:
		fail("controller steering deadzone must suppress small stick noise")
		return
	if absf(router.get_throttle() - 0.45) > 0.01 or absf(router.get_brake() - 0.35) > 0.01:
		fail("analog trigger values must remain proportional")
		return
	router.sample_analog(1.0 / 60.0, 0.56, 0.0, 0.0)
	if router.get_steering() <= 0.0 or router.get_steering() >= 0.8:
		fail("partial stick travel must produce bounded partial steering")
		return
	router.free()
	print("PASS: phase1 44_controller_input")
	quit(0)
