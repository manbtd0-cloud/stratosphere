extends SceneTree

const TEST_SUITES := [
	preload("res://tests/unit/test_project_bootstrap.gd"),
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
