class_name GameSettings
extends Resource


const CURRENT_VERSION := 1
const VALID_GRAPHICS_PROFILES := [&"low", &"medium", &"high", &"ultra", &"cinematic"]

@export var version: int = CURRENT_VERSION
@export var resolution_width: int = 1280
@export var resolution_height: int = 720
@export var fullscreen: bool = false
@export var graphics_profile: StringName = &"medium"
@export_range(0.0, 1.0, 0.01) var master_volume: float = 1.0
@export_range(0.0, 1.0, 0.01) var music_volume: float = 0.75
@export_range(0.0, 1.0, 0.01) var effects_volume: float = 1.0
@export_range(55.0, 110.0, 1.0) var camera_fov: float = 75.0
@export_range(0.0, 2.0, 0.05) var traffic_density: float = 1.0
@export var traction_control_enabled: bool = true
@export var abs_enabled: bool = true
@export var stability_control_enabled: bool = true
@export var automatic_transmission: bool = true


func sanitized_copy() -> GameSettings:
	var result := GameSettings.new()
	result.version = CURRENT_VERSION
	result.resolution_width = clampi(resolution_width, 960, 7680)
	result.resolution_height = clampi(resolution_height, 540, 4320)
	result.fullscreen = fullscreen
	result.graphics_profile = graphics_profile if graphics_profile in VALID_GRAPHICS_PROFILES else &"medium"
	result.master_volume = clampf(master_volume, 0.0, 1.0)
	result.music_volume = clampf(music_volume, 0.0, 1.0)
	result.effects_volume = clampf(effects_volume, 0.0, 1.0)
	result.camera_fov = clampf(camera_fov, 55.0, 110.0)
	result.traffic_density = clampf(traffic_density, 0.0, 2.0)
	result.traction_control_enabled = traction_control_enabled
	result.abs_enabled = abs_enabled
	result.stability_control_enabled = stability_control_enabled
	result.automatic_transmission = automatic_transmission
	return result


func to_dictionary() -> Dictionary:
	var value := sanitized_copy()
	return {
		"version": value.version,
		"resolution_width": value.resolution_width,
		"resolution_height": value.resolution_height,
		"fullscreen": value.fullscreen,
		"graphics_profile": String(value.graphics_profile),
		"master_volume": value.master_volume,
		"music_volume": value.music_volume,
		"effects_volume": value.effects_volume,
		"camera_fov": value.camera_fov,
		"traffic_density": value.traffic_density,
		"traction_control_enabled": value.traction_control_enabled,
		"abs_enabled": value.abs_enabled,
		"stability_control_enabled": value.stability_control_enabled,
		"automatic_transmission": value.automatic_transmission,
	}


static func from_dictionary(payload: Dictionary) -> GameSettings:
	var result := GameSettings.new()
	if payload.has("resolution_width"):
		result.resolution_width = int(payload["resolution_width"])
	if payload.has("resolution_height"):
		result.resolution_height = int(payload["resolution_height"])
	if payload.has("fullscreen"):
		result.fullscreen = bool(payload["fullscreen"])
	if payload.has("graphics_profile"):
		result.graphics_profile = StringName(str(payload["graphics_profile"]))
	if payload.has("master_volume"):
		result.master_volume = float(payload["master_volume"])
	if payload.has("music_volume"):
		result.music_volume = float(payload["music_volume"])
	if payload.has("effects_volume"):
		result.effects_volume = float(payload["effects_volume"])
	if payload.has("camera_fov"):
		result.camera_fov = float(payload["camera_fov"])
	if payload.has("traffic_density"):
		result.traffic_density = float(payload["traffic_density"])
	if payload.has("traction_control_enabled"):
		result.traction_control_enabled = bool(payload["traction_control_enabled"])
	if payload.has("abs_enabled"):
		result.abs_enabled = bool(payload["abs_enabled"])
	if payload.has("stability_control_enabled"):
		result.stability_control_enabled = bool(payload["stability_control_enabled"])
	if payload.has("automatic_transmission"):
		result.automatic_transmission = bool(payload["automatic_transmission"])
	return result.sanitized_copy()
