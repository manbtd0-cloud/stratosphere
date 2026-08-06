class_name SaveService
extends Node


const SaveDataType = preload("res://src/persistence/save_data.gd")

var root_directory := "user://saves"


func _init(root_override: String = "") -> void:
	if not root_override.is_empty():
		root_directory = root_override.trim_suffix("/")


func load_slot(slot: int) -> SaveData:
	if slot < 0:
		return SaveDataType.new()
	var live := _slot_path(slot, "json")
	var backup := _slot_path(slot, "bak")
	var live_result := _load_payload(live)
	if not live_result.is_empty():
		return SaveDataType.from_dictionary(live_result)
	var backup_result := _load_payload(backup)
	if not backup_result.is_empty():
		return SaveDataType.from_dictionary(backup_result)
	return SaveDataType.new()


func write_slot(slot: int, data: SaveData) -> Error:
	if slot < 0 or data == null:
		return ERR_INVALID_PARAMETER
	var make_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(root_directory)
	)
	if make_error != OK and make_error != ERR_ALREADY_EXISTS:
		return make_error

	var live := _slot_path(slot, "json")
	var temp := _slot_path(slot, "tmp")
	var backup := _slot_path(slot, "bak")
	var temp_file := FileAccess.open(temp, FileAccess.WRITE)
	if temp_file == null:
		return FileAccess.get_open_error()
	temp_file.store_string(JSON.stringify(data.to_dictionary(), "\t"))
	temp_file.flush()
	temp_file.close()

	var parsed_temp := _load_payload(temp)
	if parsed_temp.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
		return ERR_FILE_CORRUPT

	var absolute_live := ProjectSettings.globalize_path(live)
	var absolute_temp := ProjectSettings.globalize_path(temp)
	var absolute_backup := ProjectSettings.globalize_path(backup)
	if FileAccess.file_exists(live):
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(absolute_backup)
		var copy_error := DirAccess.copy_absolute(absolute_live, absolute_backup)
		if copy_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return copy_error
		var remove_error := DirAccess.remove_absolute(absolute_live)
		if remove_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return remove_error
	return DirAccess.rename_absolute(absolute_temp, absolute_live)


func delete_slot(slot: int) -> Error:
	if slot < 0:
		return ERR_INVALID_PARAMETER
	var result := OK
	for extension in ["json", "tmp", "bak"]:
		var path := _slot_path(slot, extension)
		if FileAccess.file_exists(path):
			var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if remove_error != OK:
				result = remove_error
	return result


func has_slot(slot: int) -> bool:
	return slot >= 0 and not _load_payload(_slot_path(slot, "json")).is_empty()


func migrate(payload: Dictionary, from_version: int) -> Dictionary:
	if from_version > SaveDataType.CURRENT_VERSION or from_version < 0:
		return {}
	var migrated := payload.duplicate(true)
	var version := from_version
	while version < SaveDataType.CURRENT_VERSION:
		match version:
			0:
				migrated["settings_profile"] = migrated.get("settings_profile", "default")
				version = 1
			_:
				return {}
	migrated["version"] = SaveDataType.CURRENT_VERSION
	return migrated


func _load_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var parsed = parser.data
	if not parsed is Dictionary:
		return {}
	var version := int(parsed.get("version", 0))
	return migrate(parsed, version)


func _slot_path(slot: int, extension: String) -> String:
	return "%s/slot-%d.%s" % [root_directory, slot, extension]
