class_name TrafficRosterFactory
extends RefCounted

const PACK_ONE_URL := "https://www.fab.com/listings/dc1ada50-2523-44b1-b0e2-a72d14076fb4"
const PACK_TWO_URL := "https://www.fab.com/listings/591e3b3f-9d49-4cd2-8e28-d471c1a10cab"
const DEVELOPMENT_PATHS := [
	"res://assets/traffic/development/compact.tres",
	"res://assets/traffic/development/sedan.tres",
	"res://assets/traffic/development/crossover.tres",
	"res://assets/traffic/development/utility.tres",
	"res://assets/traffic/development/van.tres",
]

static func create_development_roster() -> Array[TrafficVehicleDefinition]:
	var result: Array[TrafficVehicleDefinition] = []
	for path in DEVELOPMENT_PATHS:
		var definition := load(path) as TrafficVehicleDefinition
		if definition != null:
			result.append(definition.duplicate(true) as TrafficVehicleDefinition)
	return result

static func asset_records() -> Array[AssetRecord]:
	var result: Array[AssetRecord] = []
	for path in DEVELOPMENT_PATHS:
		var definition := load(path) as TrafficVehicleDefinition
		if definition == null:
			continue
		var record := AssetRecord.new()
		record.id = definition.id
		record.kind = &"vehicle_traffic"
		record.source = "internal://phase3/procedural-traffic-standin"
		record.license_status = &"internal_development"
		record.runtime_path = path
		record.scale_meters = 1.0
		record.forward_axis = &"-Z"
		record.up_axis = &"+Y"
		record.triangle_count = 12
		record.material_count = 1
		record.max_texture_resolution = 0
		record.collision_status = &"box_proxy"
		record.lod_count = 3
		record.shadow_mesh_ready = true
		record.rig_status = &"not_required"
		record.cockpit_suitability = &"not_applicable"
		record.runtime_status = &"development"
		record.cleanup_notes = _candidate_note(definition.id)
		result.append(record)
	return result

static func _candidate_note(definition_id: StringName) -> String:
	if definition_id in [&"traffic.vehicle.compact", &"traffic.vehicle.crossover", &"traffic.vehicle.utility"]:
		return "Procedural Phase 3 stand-in. Production candidate: Fab Vehicle Variety Pack (free; Unreal package; conversion required): %s" % PACK_ONE_URL
	return "Procedural Phase 3 stand-in. Production candidate: Fab Vehicle Variety Pack Volume 2 (free; Unreal package; conversion required): %s" % PACK_TWO_URL
