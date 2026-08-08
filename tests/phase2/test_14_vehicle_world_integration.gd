extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var scene := load("res://scenes/world/proving_region.tscn") as PackedScene
	if scene == null:
		fail("Phase 2 proving-region scene must load")
		return
	var world = scene.instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	var player: VehicleController = world.get_player_vehicle()
	var manager: WorldStreamManager = world.get_stream_manager()
	var patches := world.get_node_or_null("WorldRuntime/EnvironmentRoot/SurfaceTestPatches") as Node3D
	if player == null or manager == null or patches == null:
		fail("world must expose player, streamer, and deterministic surface test patches")
		world.queue_free(); await process_frame
		return
	player.debug_force_override = true
	for spec in [["Gravel", &"gravel"], ["Dirt", &"dirt"], ["Grass", &"grass"]]:
		var patch := patches.get_node_or_null(spec[0]) as StaticBody3D
		if patch == null or SurfaceResolver.surface_id_from_collider(patch) != spec[1]:
			fail("missing or invalid %s patch" % spec[0])
			world.queue_free(); await process_frame
			return
		_teleport_vehicle(player, patch.global_position + Vector3.UP * 1.05)
		for _frame in range(70):
			await physics_frame
		var telemetry: Dictionary = player.get_telemetry_snapshot()
		var matching := 0
		for wheel_id in ["fl", "fr", "rl", "rr"]:
			if telemetry.wheels[wheel_id].grounded and telemetry.wheels[wheel_id].surface == spec[1]:
				matching += 1
		if matching < 3:
			fail("vehicle wheel telemetry did not resolve %s surface (%d/4)" % [spec[1], matching])
			world.queue_free(); await process_frame
			return
	_teleport_vehicle(player, Vector3(0, 1.25, 500))
	for _frame in range(70):
		await physics_frame
	var asphalt: Dictionary = player.get_telemetry_snapshot()
	var asphalt_wheels := 0
	for wheel_id in ["fl", "fr", "rl", "rr"]:
		if asphalt.wheels[wheel_id].grounded and asphalt.wheels[wheel_id].surface == &"asphalt_dry":
			asphalt_wheels += 1
	if asphalt_wheels < 3:
		fail("spawn/highway surface must reach vehicle telemetry as asphalt")
		world.queue_free(); await process_frame
		return
	var before_ids := manager.loaded_cell_ids()
	_teleport_vehicle(player, Vector3(620, 1.25, 500))
	for _frame in range(8):
		await physics_frame
	var after_ids := manager.loaded_cell_ids()
	if before_ids == after_ids:
		fail("cross-cell traversal must update streamed terrain residency")
		world.queue_free(); await process_frame
		return
	if world.get_node_or_null("WorldRuntime/RoadsRoot") == null or not is_instance_valid(player):
		fail("player and road world must survive representative cell crossing")
		world.queue_free(); await process_frame
		return
	world.queue_free()
	await process_frame
	print("PASS: phase2 14_vehicle_world_integration")
	quit(0)

func _teleport_vehicle(player: VehicleController, position: Vector3) -> void:
	player.linear_velocity = Vector3.ZERO
	player.angular_velocity = Vector3.ZERO
	player.global_position = position
	player.global_rotation = Vector3.ZERO
	player.sleeping = false
	player.reset_physics_interpolation()
