extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var world = (load("res://scenes/world/proving_region.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame; await physics_frame
	if not world.has_method("get_traffic_manager"):
		fail("Phase 3 traffic/stream integration accessor must exist") ; world.queue_free(); await process_frame; return
	var player: VehicleController = world.get_player_vehicle()
	var manager: TrafficManager = world.get_traffic_manager()
	var stream: WorldStreamManager = world.get_stream_manager()
	var environment := world.get_node_or_null("WorldRuntime/EnvironmentRoot/Phase3Environment") as Node3D
	if player == null or manager == null or stream == null or environment == null: fail("stream integration prerequisites missing") ; world.queue_free(); await process_frame; return
	var before_fingerprint := _environment_fingerprint(environment)
	var before_visibility := _visibility_fingerprint(environment)
	var before_cells := stream.loaded_cell_ids()
	_teleport(player, Vector3(1900, 1.25, 100))
	for _i in range(4): await physics_frame
	var after_cells := stream.loaded_cell_ids()
	var after_visibility := _visibility_fingerprint(environment)
	if before_cells == after_cells: fail("player traversal must change Phase 2 streamed residency") ; world.queue_free(); await process_frame; return
	if before_visibility == after_visibility: fail("Phase 3 environment visibility must follow streamed cell residency") ; world.queue_free(); await process_frame; return
	_teleport(player, Vector3(0, 1.25, 500))
	for _i in range(4): await physics_frame
	if _environment_fingerprint(environment) != before_fingerprint: fail("stream traversal must not duplicate/change deterministic environment instances") ; world.queue_free(); await process_frame; return
	if manager.active_count() > manager.desired_count_for_density(1.0) or _has_duplicates(manager.active_ids()): fail("traffic must remain bounded and uniquely owned across streaming") ; world.queue_free(); await process_frame; return
	if not is_instance_valid(player): fail("streaming must never delete player") ; world.queue_free(); await process_frame; return
	world.queue_free(); await process_frame
	print("PASS: phase3 17_streaming_environment_integration")
	quit(0)

func _environment_fingerprint(root_node: Node) -> String:
	var parts := PackedStringArray()
	for cell in root_node.get_children():
		parts.append("%s:%s" % [cell.get_meta("cell_id", &""), cell.get_meta("content_fingerprint", "")])
	parts.sort()
	return "|".join(parts).sha256_text()

func _visibility_fingerprint(root_node: Node) -> String:
	var parts := PackedStringArray()
	for cell in root_node.get_children(): parts.append("%s=%s" % [cell.get_meta("cell_id", &""), cell.visible])
	parts.sort(); return "|".join(parts)

func _has_duplicates(values: PackedStringArray) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value): return true
		seen[value] = true
	return false

func _teleport(player: VehicleController, target: Vector3) -> void:
	player.linear_velocity = Vector3.ZERO; player.angular_velocity = Vector3.ZERO; player.position = target; player.sleeping = false; player.reset_physics_interpolation()
