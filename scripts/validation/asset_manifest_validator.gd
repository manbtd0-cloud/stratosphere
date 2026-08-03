class_name AssetManifestValidator
extends RefCounted

const REQUIRED_TOP_LEVEL_KEYS := [
	"schema_version",
	"asset_id",
	"display_name",
	"unit_scale_meters",
	"forward_axis",
	"up_axis",
	"dimensions_m",
	"license",
	"generator",
	"source_blend",
	"runtime_glb",
	"required_nodes",
]

const REQUIRED_NODE_NAMES := [
	"VTOL_Blockout",
	"Body",
	"CockpitShell",
	"LeftEnginePod",
	"RightEnginePod",
	"CockpitAnchor",
	"ChaseAnchor",
	"ForwardMarker",
]


static func read_manifest(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


static func validate_path(path: String) -> Dictionary:
	var errors: Array[String] = []
	var manifest := read_manifest(path)
	if manifest.is_empty():
		errors.append("Manifest is missing, unreadable, or not a JSON object")
		return {"is_valid": false, "errors": errors}

	for key in REQUIRED_TOP_LEVEL_KEYS:
		if not manifest.has(key):
			errors.append("Missing top-level key: %s" % key)

	if int(manifest.get("schema_version", 0)) != 1:
		errors.append("schema_version must equal 1")
	if not is_equal_approx(float(manifest.get("unit_scale_meters", 0.0)), 1.0):
		errors.append("unit_scale_meters must equal 1.0")
	if manifest.get("forward_axis", "") != "-Z":
		errors.append("forward_axis must equal -Z")
	if manifest.get("up_axis", "") != "+Y":
		errors.append("up_axis must equal +Y")

	_validate_dimensions(manifest.get("dimensions_m", {}), errors)
	_validate_license(manifest.get("license", {}), errors)
	_validate_repository_file(manifest.get("generator", ""), ".py", "generator", errors)
	_validate_repository_file(manifest.get("source_blend", ""), ".blend", "source_blend", errors)
	_validate_repository_file(manifest.get("runtime_glb", ""), ".glb", "runtime_glb", errors)

	var required_nodes: Variant = manifest.get("required_nodes", [])
	if not required_nodes is Array:
		errors.append("required_nodes must be an array")
	else:
		for node_name in REQUIRED_NODE_NAMES:
			if not required_nodes.has(node_name):
				errors.append("Missing required node declaration: %s" % node_name)

	return {"is_valid": errors.is_empty(), "errors": errors}


static func _validate_dimensions(value: Variant, errors: Array[String]) -> void:
	if not value is Dictionary:
		errors.append("dimensions_m must be an object")
		return
	for axis in ["width", "height", "length"]:
		if float(value.get(axis, 0.0)) <= 0.0:
			errors.append("dimensions_m.%s must be positive" % axis)


static func _validate_license(value: Variant, errors: Array[String]) -> void:
	if not value is Dictionary:
		errors.append("license must be an object")
		return
	if String(value.get("type", "")).is_empty():
		errors.append("license.type must not be empty")
	if String(value.get("author", "")).is_empty():
		errors.append("license.author must not be empty")
	if not bool(value.get("commercial_use", false)):
		errors.append("license.commercial_use must be true")


static func _validate_repository_file(
	value: Variant,
	required_suffix: String,
	field_name: String,
	errors: Array[String]
) -> void:
	var path := String(value)
	if path.is_empty():
		errors.append("%s must not be empty" % field_name)
		return
	if path.is_absolute_path() or path.begins_with("res://") or path.contains(".."):
		errors.append("%s must be repository-relative" % field_name)
		return
	if not path.ends_with(required_suffix):
		errors.append("%s must end with %s" % [field_name, required_suffix])

	var resolved_path := "res://" + path
	if not FileAccess.file_exists(resolved_path):
		errors.append("%s file is missing: %s" % [field_name, path])
		return

	var file := FileAccess.open(resolved_path, FileAccess.READ)
	if file == null or file.get_length() <= 0:
		errors.append("%s file is empty or unreadable: %s" % [field_name, path])
