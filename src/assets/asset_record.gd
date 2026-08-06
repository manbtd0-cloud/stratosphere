class_name AssetRecord
extends Resource


@export var id: StringName = &""
@export var kind: StringName = &""
@export var source: String = ""
@export var license_status: StringName = &"unknown"
@export var runtime_path: String = ""
@export var scale_meters: float = 1.0
@export var forward_axis: StringName = &"-Z"
@export var up_axis: StringName = &"+Y"
@export var triangle_count: int = 0
@export var material_count: int = 0
@export var max_texture_resolution: int = 0
@export var collision_status: StringName = &"missing"
@export var lod_count: int = 0
@export var shadow_mesh_ready: bool = false
@export var rig_status: StringName = &"not_required"
@export var cockpit_suitability: StringName = &"not_applicable"
@export var cleanup_notes: String = ""
@export var runtime_status: StringName = &"candidate"
@export var budget_exception_reason: String = ""


func to_dictionary() -> Dictionary:
	return {
		"id": String(id),
		"kind": String(kind),
		"source": source,
		"license_status": String(license_status),
		"runtime_path": runtime_path,
		"scale_meters": scale_meters,
		"forward_axis": String(forward_axis),
		"up_axis": String(up_axis),
		"triangle_count": triangle_count,
		"material_count": material_count,
		"max_texture_resolution": max_texture_resolution,
		"collision_status": String(collision_status),
		"lod_count": lod_count,
		"shadow_mesh_ready": shadow_mesh_ready,
		"rig_status": String(rig_status),
		"cockpit_suitability": String(cockpit_suitability),
		"cleanup_notes": cleanup_notes,
		"runtime_status": String(runtime_status),
		"budget_exception_reason": budget_exception_reason,
	}


func duplicate_record() -> AssetRecord:
	var result := AssetRecord.new()
	result.id = id
	result.kind = kind
	result.source = source
	result.license_status = license_status
	result.runtime_path = runtime_path
	result.scale_meters = scale_meters
	result.forward_axis = forward_axis
	result.up_axis = up_axis
	result.triangle_count = triangle_count
	result.material_count = material_count
	result.max_texture_resolution = max_texture_resolution
	result.collision_status = collision_status
	result.lod_count = lod_count
	result.shadow_mesh_ready = shadow_mesh_ready
	result.rig_status = rig_status
	result.cockpit_suitability = cockpit_suitability
	result.cleanup_notes = cleanup_notes
	result.runtime_status = runtime_status
	result.budget_exception_reason = budget_exception_reason
	return result
