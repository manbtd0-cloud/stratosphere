class_name ProjectContractValidator
extends RefCounted

const REQUIRED_PATHS := [
	"res://project.godot",
	"res://export_presets.cfg",
	"res://scenes/flight_room/flight_room.tscn",
	"res://scenes/flight_room/flight_room_environment.tscn",
	"res://scenes/craft/frontier_vtol.tscn",
	"res://scenes/craft/flight_camera_rig.tscn",
	"res://scenes/ui/flight_hud.tscn",
	"res://scripts/flight/flight_model.gd",
	"res://scripts/flight/frontier_vtol_controller.gd",
	"res://scripts/flight/flight_feedback.gd",
	"res://scripts/input/pilot_input_adapter.gd",
	"res://scripts/camera/flight_camera_rig.gd",
	"res://scripts/game/flight_room_controller.gd",
	"res://scripts/validation/asset_manifest_validator.gd",
	"res://assets/generated/vtol_blockout.asset.json",
	"res://assets/generated/vtol_blockout.glb",
	"res://assets/source/vtol_blockout.blend",
	"res://tools/blender/build_vtol_blockout.py",
	"res://tools/blender/generate_vtol_blockout.py",
	"res://tools/verify/verify.py",
	"res://tests/gameplay_smoke_runner.gd",
]

const EXPECTED_MAIN_SCENE := "res://scenes/flight_room/flight_room.tscn"
const EXPECTED_PHYSICS_TICKS := 120
const EXPECTED_EXPORT_PRESET := "Windows Desktop"
const EXPECTED_EXPORT_PATH := "build/windows/STRATOSPHERE.exe"


static func validate() -> Dictionary:
	var errors: Array[String] = []

	for path in REQUIRED_PATHS:
		if not FileAccess.file_exists(path):
			errors.append("Missing required path: %s" % path)

	var main_scene := String(
		ProjectSettings.get_setting("application/run/main_scene", "")
	)
	if main_scene != EXPECTED_MAIN_SCENE:
		errors.append(
			"Main scene must be %s, got %s" % [EXPECTED_MAIN_SCENE, main_scene]
		)

	var physics_ticks := int(
		ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 0)
	)
	if physics_ticks != EXPECTED_PHYSICS_TICKS:
		errors.append(
			"Physics tick rate must be %d, got %d"
			% [EXPECTED_PHYSICS_TICKS, physics_ticks]
		)

	_validate_export_preset(errors)
	return {"is_valid": errors.is_empty(), "errors": errors}


static func _validate_export_preset(errors: Array[String]) -> void:
	var preset_path := "res://export_presets.cfg"
	if not FileAccess.file_exists(preset_path):
		return
	var preset_text := FileAccess.get_file_as_string(preset_path)
	if not preset_text.contains('name="%s"' % EXPECTED_EXPORT_PRESET):
		errors.append("Missing Windows Desktop export preset")
	if not preset_text.contains('platform="Windows Desktop"'):
		errors.append("Windows export preset has the wrong platform")
	if not preset_text.contains('export_path="%s"' % EXPECTED_EXPORT_PATH):
		errors.append("Windows export path must be %s" % EXPECTED_EXPORT_PATH)