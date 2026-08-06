class_name SaveData
extends Resource


const CURRENT_VERSION := 1

@export var version: int = CURRENT_VERSION
@export var money: int = 0
@export var reputation: int = 0
@export var licenses: PackedStringArray = PackedStringArray()
@export var championships: Dictionary = {}
@export var owned_vehicles: PackedStringArray = PackedStringArray()
@export var vehicle_tuning: Dictionary = {}
@export var vehicle_upgrades: Dictionary = {}
@export var vehicle_damage: Dictionary = {}
@export var event_results: Dictionary = {}
@export var discovered_locations: PackedStringArray = PackedStringArray()
@export var unlocked_regions: PackedStringArray = PackedStringArray()
@export var current_vehicle: StringName = &""
@export var settings_profile: StringName = &"default"


func to_dictionary() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"money": maxi(money, 0),
		"reputation": maxi(reputation, 0),
		"licenses": Array(licenses),
		"championships": championships.duplicate(true),
		"owned_vehicles": Array(owned_vehicles),
		"vehicle_tuning": vehicle_tuning.duplicate(true),
		"vehicle_upgrades": vehicle_upgrades.duplicate(true),
		"vehicle_damage": vehicle_damage.duplicate(true),
		"event_results": event_results.duplicate(true),
		"discovered_locations": Array(discovered_locations),
		"unlocked_regions": Array(unlocked_regions),
		"current_vehicle": String(current_vehicle),
		"settings_profile": String(settings_profile),
	}


static func from_dictionary(payload: Dictionary) -> SaveData:
	var result := SaveData.new()
	result.version = int(payload.get("version", CURRENT_VERSION))
	result.money = maxi(int(payload.get("money", 0)), 0)
	result.reputation = maxi(int(payload.get("reputation", 0)), 0)
	result.licenses = PackedStringArray(payload.get("licenses", []))
	result.championships = _dictionary_or_empty(payload.get("championships", {}))
	result.owned_vehicles = PackedStringArray(payload.get("owned_vehicles", []))
	result.vehicle_tuning = _dictionary_or_empty(payload.get("vehicle_tuning", {}))
	result.vehicle_upgrades = _dictionary_or_empty(payload.get("vehicle_upgrades", {}))
	result.vehicle_damage = _dictionary_or_empty(payload.get("vehicle_damage", {}))
	result.event_results = _dictionary_or_empty(payload.get("event_results", {}))
	result.discovered_locations = PackedStringArray(payload.get("discovered_locations", []))
	result.unlocked_regions = PackedStringArray(payload.get("unlocked_regions", []))
	result.current_vehicle = StringName(str(payload.get("current_vehicle", "")))
	result.settings_profile = StringName(str(payload.get("settings_profile", "default")))
	return result


static func _dictionary_or_empty(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}
