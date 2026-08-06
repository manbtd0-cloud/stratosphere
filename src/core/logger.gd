extends Node


const MAX_RECENT_ENTRIES := 500

var _recent_entries: Array[Dictionary] = []
var _session_file: FileAccess
var _initialized := false


func info(category: StringName, message: String, context: Dictionary = {}) -> void:
	_append_entry(&"info", category, message, context)


func warning(category: StringName, message: String, context: Dictionary = {}) -> void:
	_append_entry(&"warning", category, message, context)


func error(category: StringName, message: String, context: Dictionary = {}) -> void:
	_append_entry(&"error", category, message, context)


func get_recent_entries() -> Array[Dictionary]:
	return _recent_entries.duplicate(true)


func _append_entry(
	level: StringName,
	category: StringName,
	message: String,
	context: Dictionary
) -> void:
	_ensure_initialized()
	var entry: Dictionary = {
		"timestamp_utc": Time.get_datetime_string_from_system(true, true),
		"level": level,
		"category": category,
		"message": message,
		"context": context.duplicate(true),
	}
	_recent_entries.append(entry)
	if _recent_entries.size() > MAX_RECENT_ENTRIES:
		_recent_entries.pop_front()

	var line := _format_entry(entry)
	print(line)
	if _session_file != null:
		_session_file.store_line(JSON.stringify(entry))
		_session_file.flush()


func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	var logs_dir := "user://logs"
	var absolute_logs_dir := ProjectSettings.globalize_path(logs_dir)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_logs_dir)
	if make_error != OK and make_error != ERR_ALREADY_EXISTS:
		push_warning("Unable to create log directory: %s" % error_string(make_error))
		return
	var timestamp := Time.get_datetime_string_from_system(true, true)
	timestamp = timestamp.replace(":", "-")
	var log_path := "%s/session-%s-%s.jsonl" % [logs_dir, timestamp, Time.get_ticks_usec()]
	_session_file = FileAccess.open(log_path, FileAccess.WRITE)
	if _session_file == null:
		push_warning("Unable to open session log: %s" % error_string(FileAccess.get_open_error()))


func _format_entry(entry: Dictionary) -> String:
	var suffix := ""
	var context: Dictionary = entry["context"]
	if not context.is_empty():
		suffix = " %s" % JSON.stringify(context)
	return "[%s] [%s] [%s] %s%s" % [
		entry["timestamp_utc"],
		String(entry["level"]).to_upper(),
		entry["category"],
		entry["message"],
		suffix,
	]
