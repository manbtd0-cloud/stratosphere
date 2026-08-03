extends SceneTree

const TEST_SUITES := [
	preload("res://tests/unit/test_project_bootstrap.gd"),
	preload("res://tests/unit/test_simulation_clock.gd"),
	preload("res://tests/unit/test_pilot_command.gd"),
	preload("res://tests/unit/test_atmosphere_model.gd"),
	preload("res://tests/unit/test_flight_model.gd"),
	preload("res://tests/integration/test_frontier_vtol_controller.gd"),
]


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var total := 0
	for suite_script in TEST_SUITES:
		var suite: TestCase = suite_script.new()
		total += suite.run()
	print("PASS: %d tests" % total)
	quit(0)