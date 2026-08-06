class_name AssetRegistry
extends Node


const ALLOWED_KINDS := [
	&"vehicle_hero", &"vehicle_traffic", &"environment", &"prop", &"audio",
	&"ui", &"material", &"texture", &"tool"
]

var _records: Dictionary = {}


func register(record: AssetRecord) -> Error:
	if record == null:
		return ERR_INVALID_PARAMETER
	if _records.has(record.id):
		return ERR_ALREADY_EXISTS
	var issues := validate_record(record)
	if not issues.is_empty():
		return ERR_INVALID_DATA
	_records[record.id] = record.duplicate_record()
	return OK


func get_record(id: StringName) -> AssetRecord:
	if not _records.has(id):
		return null
	return (_records[id] as AssetRecord).duplicate_record()


func all_records() -> Array[AssetRecord]:
	var records: Array[AssetRecord] = []
	for key in _records.keys():
		records.append((_records[key] as AssetRecord).duplicate_record())
	records.sort_custom(func(a: AssetRecord, b: AssetRecord) -> bool: return String(a.id) < String(b.id))
	return records


func validate_record(record: AssetRecord) -> PackedStringArray:
	var issues := PackedStringArray()
	if record == null:
		issues.append("record must not be null")
		return issues
	var id_text := String(record.id)
	if id_text.is_empty():
		issues.append("id must not be empty")
	elif id_text != id_text.to_lower() or not id_text.contains("."):
		issues.append("id must be lowercase and namespaced")
	if record.kind not in ALLOWED_KINDS:
		issues.append("unknown asset kind: %s" % record.kind)
	if record.source.strip_edges().is_empty():
		issues.append("source must not be empty")
	if record.runtime_path.is_empty() or not FileAccess.file_exists(record.runtime_path):
		issues.append("runtime path must exist")
	if record.scale_meters <= 0.0:
		issues.append("scale_meters must be positive")
	if record.forward_axis != &"-Z" or record.up_axis != &"+Y":
		issues.append("asset axes must be -Z forward and +Y up")
	if record.triangle_count < 0 or record.material_count < 0 or record.max_texture_resolution < 0:
		issues.append("asset counts must not be negative")
	if record.kind == &"vehicle_hero":
		if record.lod_count < 4:
			issues.append("hero vehicle requires at least four LOD states")
		if record.material_count > 14 and record.budget_exception_reason.strip_edges().is_empty():
			issues.append("hero vehicle exceeds fourteen materials without exception")
		if record.cockpit_suitability not in [&"full", &"partial"]:
			issues.append("hero vehicle must declare cockpit suitability")
	if record.kind == &"vehicle_traffic":
		if record.lod_count < 3:
			issues.append("traffic vehicle requires at least three LOD states")
		if record.material_count > 7 and record.budget_exception_reason.strip_edges().is_empty():
			issues.append("traffic vehicle exceeds seven materials without exception")
	return issues


func export_audit(path: String) -> Error:
	var parent := ProjectSettings.globalize_path(path.get_base_dir())
	var make_error := DirAccess.make_dir_recursive_absolute(parent)
	if make_error != OK and make_error != ERR_ALREADY_EXISTS:
		return make_error
	var payload: Array[Dictionary] = []
	for record in all_records():
		payload.append(record.to_dictionary())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"assets": payload}, "\t"))
	file.flush()
	file.close()
	return OK
