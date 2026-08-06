class_name RenderQualityProfile
extends Resource


@export var profile_id: StringName = &"medium"
@export_range(0.5, 1.5, 0.01) var render_scale: float = 0.77
@export_enum("Bilinear:0", "FSR 1.0:1", "FSR 2.2:2") var scaling_mode: int = 2
@export_range(0.1, 8.0, 0.1) var mesh_lod_threshold: float = 1.0
@export_range(0.0, 2.0, 0.05) var vegetation_density: float = 1.0
@export_range(0.0, 2.0, 0.05) var prop_density: float = 1.0
@export_range(0.0, 2.0, 0.05) var traffic_density: float = 1.0
@export_range(0.0, 2000.0, 10.0) var decal_distance: float = 350.0
@export_range(0, 3, 1) var shadow_quality: int = 1
@export var volumetric_fog_enabled: bool = true
@export var ssao_enabled: bool = true
@export var ssil_enabled: bool = false
@export var ssr_enabled: bool = false
@export var sdfgi_enabled: bool = false
@export var glow_enabled: bool = true
@export var developer_only: bool = false


func sanitized_copy() -> RenderQualityProfile:
	var result := RenderQualityProfile.new()
	result.profile_id = profile_id
	result.render_scale = clampf(render_scale, 0.5, 1.5)
	result.scaling_mode = clampi(scaling_mode, 0, 2)
	result.mesh_lod_threshold = clampf(mesh_lod_threshold, 0.1, 8.0)
	result.vegetation_density = clampf(vegetation_density, 0.0, 2.0)
	result.prop_density = clampf(prop_density, 0.0, 2.0)
	result.traffic_density = clampf(traffic_density, 0.0, 2.0)
	result.decal_distance = clampf(decal_distance, 0.0, 2000.0)
	result.shadow_quality = clampi(shadow_quality, 0, 3)
	result.volumetric_fog_enabled = volumetric_fog_enabled
	result.ssao_enabled = ssao_enabled
	result.ssil_enabled = ssil_enabled
	result.ssr_enabled = ssr_enabled
	result.sdfgi_enabled = sdfgi_enabled
	result.glow_enabled = glow_enabled
	result.developer_only = developer_only
	return result


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if profile_id == &"":
		errors.append("profile_id must not be empty")
	if render_scale < 0.5 or render_scale > 1.5:
		errors.append("render_scale must be between 0.5 and 1.5")
	if mesh_lod_threshold < 0.1 or mesh_lod_threshold > 8.0:
		errors.append("mesh_lod_threshold must be between 0.1 and 8.0")
	return errors
