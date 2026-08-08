class_name SurfaceResolver
extends RefCounted

const SUPPORTED_IDS := [&"asphalt_dry", &"asphalt_wet", &"gravel", &"dirt", &"grass"]

static func surface_id_from_collider(collider: Object, fallback: StringName = &"asphalt_dry") -> StringName:
	var safe_fallback := fallback if is_supported_id(fallback) else &"asphalt_dry"
	if collider == null or not collider.has_meta("surface_id"):
		return safe_fallback
	var value := StringName(collider.get_meta("surface_id"))
	return value if is_supported_id(value) else safe_fallback

static func is_supported_id(surface_id: StringName) -> bool:
	return surface_id in SUPPORTED_IDS
