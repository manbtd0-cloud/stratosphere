extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var factory_script = load("res://src/traffic/traffic_roster_factory.gd")
	if factory_script == null:
		fail("TrafficRosterFactory script must exist")
		return
	var definitions: Array[TrafficVehicleDefinition] = factory_script.create_development_roster()
	if definitions.size() < 3 or definitions.size() > 5:
		fail("Phase 3 traffic roster must contain 3-5 archetypes")
		return
	var ids: Dictionary = {}
	for definition in definitions:
		if definition == null or not definition.validation_errors().is_empty():
			fail("traffic roster definitions must validate")
			return
		if ids.has(definition.id): fail("traffic roster IDs must be unique"); return
		ids[definition.id] = true
		if definition.dimensions_m.x < 1.5 or definition.dimensions_m.z < 3.5 or definition.wheelbase_m <= 2.0:
			fail("traffic archetype dimensions/wheelbase must be plausible")
			return
	var required := [&"traffic.vehicle.compact", &"traffic.vehicle.sedan", &"traffic.vehicle.crossover", &"traffic.vehicle.utility", &"traffic.vehicle.van"]
	for id in required:
		if not ids.has(id): fail("missing traffic archetype: %s" % id); return
	var records: Array[AssetRecord] = factory_script.asset_records()
	if records.size() != definitions.size(): fail("each traffic archetype needs an asset/provenance record"); return
	var registry := AssetRegistry.new()
	for record in records:
		if record.kind != &"vehicle_traffic" or record.source.strip_edges().is_empty() or record.cleanup_notes.strip_edges().is_empty():
			fail("traffic record must declare kind/source/provenance notes")
			registry.free(); return
		if record.runtime_status != &"development" or record.lod_count < 3:
			fail("development traffic record must expose runtime status and >=3 LOD states")
			registry.free(); return
		if registry.register(record) != OK:
			fail("traffic asset record must satisfy AssetRegistry contract: %s" % record.id)
			registry.free(); return
	registry.free()
	print("PASS: phase3 18_traffic_roster")
	quit(0)
