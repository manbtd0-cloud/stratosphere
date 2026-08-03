class_name TestProjectBootstrap
extends TestCase


func test_project_name() -> void:
	TestAssert.is_equal(
		ProjectSettings.get_setting("application/config/name"),
		"STRATOSPHERE: Frontier Vector"
	)


func test_physics_tick_rate() -> void:
	TestAssert.is_equal(
		ProjectSettings.get_setting("physics/common/physics_ticks_per_second"),
		120
	)
