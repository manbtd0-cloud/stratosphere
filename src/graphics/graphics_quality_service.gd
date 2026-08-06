class_name GraphicsQualityService
extends Node


const PROFILE_ROOT := "res://data/graphics"
const PROFILE_IDS := [&"low", &"medium", &"high", &"ultra", &"cinematic"]

var active_profile: RenderQualityProfile


func load_profile(profile_id: StringName) -> RenderQualityProfile:
	if profile_id not in PROFILE_IDS:
		return null
	var resource = load("%s/%s.tres" % [PROFILE_ROOT, profile_id])
	if resource == null or not resource is RenderQualityProfile:
		return null
	return resource


func apply_profile(profile: RenderQualityProfile, viewport: Viewport = null) -> PackedStringArray:
	if profile == null:
		return PackedStringArray(["profile must not be null"])
	var errors := profile.validation_errors()
	if not errors.is_empty():
		return errors
	var sanitized := profile.sanitized_copy()
	var target_viewport := viewport
	if target_viewport == null and is_inside_tree():
		target_viewport = get_tree().root
	if target_viewport != null:
		target_viewport.scaling_3d_mode = sanitized.scaling_mode as Viewport.Scaling3DMode
		target_viewport.scaling_3d_scale = sanitized.render_scale
		target_viewport.mesh_lod_threshold = sanitized.mesh_lod_threshold
	active_profile = sanitized
	return PackedStringArray()


func apply_to_environment(environment: Environment, profile: RenderQualityProfile) -> PackedStringArray:
	if environment == null:
		return PackedStringArray(["environment must not be null"])
	if profile == null:
		return PackedStringArray(["profile must not be null"])
	var errors := profile.validation_errors()
	if not errors.is_empty():
		return errors
	var sanitized := profile.sanitized_copy()
	environment.volumetric_fog_enabled = sanitized.volumetric_fog_enabled
	environment.ssao_enabled = sanitized.ssao_enabled
	environment.ssil_enabled = sanitized.ssil_enabled
	environment.ssr_enabled = sanitized.ssr_enabled
	environment.sdfgi_enabled = sanitized.sdfgi_enabled
	environment.glow_enabled = sanitized.glow_enabled
	return PackedStringArray()
