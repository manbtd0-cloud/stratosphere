extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var manager_script = load("res://src/traffic/traffic_manager.gd")
	if manager_script == null:
		fail("TrafficManager script must exist")
		return
	var region := DrivingRegionFactory.create()
	var graph := TrafficLaneGraphBuilder.new().build(region.base_definition.road_network, region.base_definition.grid)
	var definitions: Array[TrafficVehicleDefinition] = []
	for suffix in ["compact", "sedan", "utility"]:
		var definition := TrafficVehicleDefinition.new()
		definition.id = StringName("traffic.vehicle.%s" % suffix)
		definitions.append(definition)
	var manager = manager_script.new()
	root.add_child(manager)
	var errors: PackedStringArray = manager.configure(graph, definitions, 12, 20)
	if not errors.is_empty(): fail("valid traffic manager config rejected: %s" % errors); manager.queue_free(); await process_frame; return
	var player := Transform3D(Basis.IDENTITY, Vector3.ZERO)
	manager.spawn_to_target(player, 1.0)
	if manager.active_count() <= 0 or manager.active_count() > 12:
		fail("manager must create a bounded initial traffic population"); manager.queue_free(); await process_frame; return
	if _has_duplicates(manager.active_ids()): fail("manager must never own duplicate traffic IDs"); manager.queue_free(); await process_frame; return
	if manager.desired_count_for_density(2.0) > 20 or manager.desired_count_for_density(0.0) != 0:
		fail("traffic density scaling must obey global budget"); manager.queue_free(); await process_frame; return
	var active_before: int = manager.active_count()
	var first_agent: TrafficAgent = manager.agent_for_id(manager.active_ids()[0])
	if manager.register_existing(first_agent, &"world.proving.cp00_p00") != ERR_ALREADY_EXISTS:
		fail("duplicate traffic-agent registration must reject"); manager.queue_free(); await process_frame; return
	if manager.active_count() != active_before:
		fail("duplicate registration must not change population"); manager.queue_free(); await process_frame; return
	manager.reconcile_loaded_cells(PackedStringArray())
	await process_frame
	if manager.active_count() != 0:
		fail("unloaded cells must release all owned traffic agents"); manager.queue_free(); await process_frame; return
	for _cycle in range(4):
		manager.spawn_to_target(player, 0.75)
		if manager.active_count() > manager.desired_count_for_density(0.75) or _has_duplicates(manager.active_ids()):
			fail("repeated traffic population cycles must remain bounded/unique"); manager.queue_free(); await process_frame; return
		manager.clear_all()
		await process_frame
		if manager.active_count() != 0: fail("clear_all must release registry ownership"); manager.queue_free(); await process_frame; return
	manager.queue_free(); await process_frame
	print("PASS: phase3 14_traffic_manager")
	quit(0)

func _has_duplicates(values: PackedStringArray) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value): return true
		seen[value] = true
	return false
