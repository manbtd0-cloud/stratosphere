class_name TestProjectContractValidator
extends TestCase


func test_phase_zero_one_contract_is_complete() -> void:
	var result := ProjectContractValidator.validate()

	TestAssert.is_true(
		result.is_valid,
		"Project contract failed: %s" % [result.errors]
	)


func test_main_scene_and_physics_rate_are_locked() -> void:
	TestAssert.is_equal(
		ProjectSettings.get_setting("application/run/main_scene"),
		"res://scenes/flight_room/flight_room.tscn"
	)
	TestAssert.is_equal(
		int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")),
		120
	)


func test_windows_export_preset_has_canonical_output() -> void:
	var preset_text := FileAccess.get_file_as_string("res://export_presets.cfg")

	TestAssert.is_true(preset_text.contains('name="Windows Desktop"'))
	TestAssert.is_true(
		preset_text.contains('export_path="build/windows/STRATOSPHERE.exe"')
	)


func test_blender_generator_is_source_controlled() -> void:
	TestAssert.is_true(
		FileAccess.file_exists("res://tools/blender/generate_vtol_blockout.py")
	)