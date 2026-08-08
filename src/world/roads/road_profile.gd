class_name RoadProfile
extends Resource

@export var id: StringName = &""
@export var lane_width_m: float = 3.4
@export var lane_count: int = 2
@export var shoulder_width_m: float = 1.0
@export var marking_policy: StringName = &"center_and_edge"
@export var base_surface_id: StringName = &"asphalt_dry"
@export var shoulder_surface_id: StringName = &"gravel"
@export var sample_spacing_m: float = 3.0
@export var coarse_lod_spacing_m: float = 12.0

static func for_id(profile_id: StringName) -> RoadProfile:
	var result := RoadProfile.new()
	result.id = profile_id
	match profile_id:
		&"highway":
			result.lane_width_m = 3.6
			result.lane_count = 4
			result.shoulder_width_m = 2.5
			result.marking_policy = &"highway"
			result.shoulder_surface_id = &"asphalt_dry"
			result.sample_spacing_m = 4.0
			result.coarse_lod_spacing_m = 16.0
		&"rural_two_lane":
			result.lane_width_m = 3.4
			result.lane_count = 2
			result.shoulder_width_m = 1.0
			result.marking_policy = &"center_and_edge"
			result.sample_spacing_m = 3.0
			result.coarse_lod_spacing_m = 12.0
		&"hill_two_lane":
			result.lane_width_m = 3.2
			result.lane_count = 2
			result.shoulder_width_m = 0.75
			result.marking_policy = &"center_and_edge"
			result.sample_spacing_m = 2.5
			result.coarse_lod_spacing_m = 10.0
		&"service":
			result.lane_width_m = 3.0
			result.lane_count = 2
			result.shoulder_width_m = 0.5
			result.marking_policy = &"center"
			result.sample_spacing_m = 3.0
			result.coarse_lod_spacing_m = 12.0
		&"dirt_trail":
			result.lane_width_m = 3.0
			result.lane_count = 1
			result.shoulder_width_m = 0.5
			result.marking_policy = &"none"
			result.base_surface_id = &"dirt"
			result.shoulder_surface_id = &"dirt"
			result.sample_spacing_m = 3.0
			result.coarse_lod_spacing_m = 12.0
		_:
			return null
	return result

func road_width_m() -> float:
	return lane_width_m * float(lane_count)

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("road profile id must not be empty")
	if lane_width_m <= 0.0:
		errors.append("lane width must be positive")
	if lane_count <= 0:
		errors.append("lane count must be positive")
	if shoulder_width_m < 0.0:
		errors.append("shoulder width must not be negative")
	if sample_spacing_m <= 0.0:
		errors.append("sample spacing must be positive")
	if coarse_lod_spacing_m < sample_spacing_m:
		errors.append("coarse LOD spacing must be at least sample spacing")
	if base_surface_id not in [&"asphalt_dry", &"asphalt_wet", &"gravel", &"dirt", &"grass"]:
		errors.append("unsupported surface id: %s" % base_surface_id)
	if shoulder_surface_id not in [&"asphalt_dry", &"asphalt_wet", &"gravel", &"dirt", &"grass"]:
		errors.append("unsupported shoulder surface id: %s" % shoulder_surface_id)
	return errors
