class_name EnvironmentZoneDefinition
extends Resource

const ALLOWED_CLASSES: Array[StringName] = [
	&"countryside_open", &"farmland", &"forest", &"hill_rocky",
	&"rural_settlement", &"industrial_service", &"highway_corridor",
	&"dirt_trail_corridor", &"scenic_overlook",
]

@export var id: StringName = &""
@export var zone_class: StringName = &"countryside_open"
@export var cell_ids: Array[StringName] = []
@export var vegetation_palette_ids: Array[StringName] = []
@export var prop_palette_ids: Array[StringName] = []
@export var density_multiplier: float = 1.0
@export var traffic_density_multiplier: float = 1.0
@export var roadside_furniture_policy: StringName = &"default"
@export var ambient_audio_hook_ids: Array[StringName] = []

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	cell_ids = _unique(cell_ids)
	vegetation_palette_ids = _unique(vegetation_palette_ids)
	prop_palette_ids = _unique(prop_palette_ids)
	ambient_audio_hook_ids = _unique(ambient_audio_hook_ids)
	if id.is_empty():
		errors.append("environment zone id must not be empty")
	if zone_class not in ALLOWED_CLASSES:
		errors.append("unsupported environment zone class: %s" % zone_class)
	if cell_ids.is_empty():
		errors.append("environment zone must own at least one cell")
	if density_multiplier < 0.0:
		errors.append("environment density multiplier must not be negative")
	if traffic_density_multiplier < 0.0:
		errors.append("traffic density multiplier must not be negative")
	return errors

func _unique(values: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		if not value.is_empty() and value not in result:
			result.append(value)
	return result
