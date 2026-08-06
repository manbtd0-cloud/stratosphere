extends SceneTree


const EXPECTED_MAIN_SCENE := "res://src/bootstrap/main.tscn"


func _init() -> void:
	var failures: Array[String] = []

	if not FileAccess.file_exists("res://project.godot"):
		failures.append("project.godot must exist")

	if not FileAccess.file_exists(EXPECTED_MAIN_SCENE):
		failures.append("main scene must exist at %s" % EXPECTED_MAIN_SCENE)

	var configured_main_scene := str(
		ProjectSettings.get_setting("application/run/main_scene", "")
	)
	if configured_main_scene != EXPECTED_MAIN_SCENE:
		failures.append(
			"application/run/main_scene must equal %s, got %s"
			% [EXPECTED_MAIN_SCENE, configured_main_scene]
		)

	var configured_name := str(ProjectSettings.get_setting("application/config/name", ""))
	if configured_name != "Open World Racing":
		failures.append("application/config/name must equal Open World Racing")

	if failures.is_empty():
		print("PASS: project baseline contract")
		quit(0)
		return

	for failure in failures:
		push_error("FAIL: %s" % failure)
	quit(1)
