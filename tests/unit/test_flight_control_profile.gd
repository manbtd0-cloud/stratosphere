class_name TestFlightControlProfile
extends TestCase


func test_response_curve_is_signed_monotonic_and_bounded() -> void:
	var profile := FlightControlProfile.new()
	profile.mouse_response_exponent = 1.4

	var small := profile.shaped_axis(0.25)
	var large := profile.shaped_axis(0.75)

	TestAssert.is_true(small > 0.0)
	TestAssert.is_true(large > small)
	TestAssert.is_near(profile.shaped_axis(-0.75), -large, 0.000001)
	TestAssert.is_equal(profile.shaped_axis(2.0), 1.0)


func test_rate_limits_blend_continuously_between_modes() -> void:
	var profile := FlightControlProfile.new()
	profile.hover_max_rate_degrees = Vector3(60.0, 50.0, 70.0)
	profile.forward_max_rate_degrees = Vector3(100.0, 30.0, 130.0)

	var hover := profile.blended_max_rate_radians(0.0)
	var middle := profile.blended_max_rate_radians(0.5)
	var forward := profile.blended_max_rate_radians(1.0)

	TestAssert.is_near(hover.x, deg_to_rad(60.0), 0.000001)
	TestAssert.is_near(middle.x, deg_to_rad(80.0), 0.000001)
	TestAssert.is_near(forward.y, deg_to_rad(30.0), 0.000001)
	TestAssert.is_true(middle.z > hover.z)
	TestAssert.is_true(middle.z < forward.z)


func test_invalid_tuning_is_sanitized() -> void:
	var profile := FlightControlProfile.new()
	profile.rate_gain_newton_meters_per_rad_s = Vector3(-1.0, INF, 100.0)
	profile.max_torque_newton_meters = Vector3(-50.0, 200.0, NAN)

	var gain := profile.safe_rate_gain()
	var limit := profile.safe_max_torque()

	TestAssert.is_true(gain.x >= 0.0)
	TestAssert.is_true(is_finite(gain.y))
	TestAssert.is_true(limit.x >= 0.0)
	TestAssert.is_true(is_finite(limit.z))


func test_default_resource_loads() -> void:
	var profile := load(
		"res://resources/flight/default_flight_control_profile.tres"
	) as FlightControlProfile

	TestAssert.is_true(profile != null)
	TestAssert.is_true(profile.full_pitch_mouse_speed_px_s > 0.0)
	TestAssert.is_true(
		profile.max_chase_fov_degrees >= profile.min_chase_fov_degrees
	)
