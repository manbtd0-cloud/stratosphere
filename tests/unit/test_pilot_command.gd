class_name TestPilotCommand
extends TestCase


func test_axes_and_scalars_are_clamped() -> void:
	var source := PilotCommand.new()
	source.pitch = 4.0
	source.yaw = -3.0
	source.roll = 2.0
	source.collective = -2.0
	source.transition = 7.0
	source.brake = -1.0
	source.strafe = Vector3(3.0, 0.0, 4.0)

	var clean := source.sanitized()

	TestAssert.is_equal(clean.pitch, 1.0)
	TestAssert.is_equal(clean.yaw, -1.0)
	TestAssert.is_equal(clean.roll, 1.0)
	TestAssert.is_equal(clean.collective, 0.0)
	TestAssert.is_equal(clean.transition, 1.0)
	TestAssert.is_equal(clean.brake, 0.0)
	TestAssert.is_near(clean.strafe.length(), 1.0, 0.000001)


func test_sanitization_returns_copy_without_mutating_source() -> void:
	var source := PilotCommand.new()
	source.pitch = 4.0
	var clean := source.sanitized()

	TestAssert.is_true(clean != source)
	TestAssert.is_equal(clean.pitch, 1.0)
	TestAssert.is_equal(source.pitch, 4.0)
