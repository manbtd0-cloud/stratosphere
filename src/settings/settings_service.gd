class_name SettingsService
extends Node


const GameSettingsType = preload("res://src/settings/game_settings.gd")

var settings_path := "user://settings.json"


func _init(path_override: String = "") -> void:
	if not path_override.is_empty():
		settings_path = path_override


func load_settings() -> GameSettings:
	if not FileAccess.file_exists(settings_path):
		return GameSettingsType.new()
	var file := FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open settings file: %s" % error_string(FileAccess.get_open_error()))
		return GameSettingsType.new()
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Settings file is not a JSON object; defaults restored")
		return GameSettingsType.new()
	return GameSettingsType.from_dictionary(parsed)


func save_settings(settings: GameSettings) -> Error:
	if settings == null:
		return ERR_INVALID_PARAMETER
	var absolute_parent := ProjectSettings.globalize_path(settings_path.get_base_dir())
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_parent)
	if make_error != OK and make_error != ERR_ALREADY_EXISTS:
		return make_error
	var temp_path := "%s.tmp" % settings_path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(settings.to_dictionary(), "\t"))
	file.flush()
	file.close()
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_live := ProjectSettings.globalize_path(settings_path)
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(absolute_live)
	return DirAccess.rename_absolute(absolute_temp, absolute_live)


func delete_settings() -> Error:
	var result := OK
	for path in [settings_path, "%s.tmp" % settings_path]:
		if FileAccess.file_exists(path):
			var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if error != OK:
				result = error
	return result
