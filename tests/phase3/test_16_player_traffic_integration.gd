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
		fail("Phase 3 traffic accessor must exist") ; world.queue_free(); await process_frame; return
	var player: VehicleController = world.get_player_vehicle()
	var manager: TrafficManager = world.get_traffic_manager()
	if player == null or manager == null or manager.active_ids().is_empty(): fail("player and active traffic required") ; world.queue_free(); await process_frame; return
	var agent: TrafficAgent = manager.agent_for_id(manager.active_ids()[0])
	if agent == null or agent.get_script() == player.get_script(): fail("traffic must remain a separate controller type") ; world.queue_free(); await process_frame; return
	if agent.get_node_or_null("CollisionShape3D") == null: fail("near/mid traffic body must carry world collision") ; world.queue_free(); await process_frame; return
	if (player.collision_layer & agent.collision_mask) == 0 or (agent.collision_layer & player.collision_mask) == 0:
		fail("player and civilian traffic collision masks must interact") ; world.queue_free(); await process_frame; return
	if not player.has_method("reset_vehicle"): fail("Phase 1 player recovery/reset contract must survive traffic integration") ; world.queue_free(); await process_frame; return
	var player_script: Script = player.get_script() as Script
	manager.update_simulation_levels(player.position)
	await physics_frame
	if player.get_script() != player_script: fail("traffic integration must never replace player controller") ; world.queue_free(); await process_frame; return
	player.reset_vehicle()
	await physics_frame
	if not is_instance_valid(player): fail("player reset must remain functional with traffic active") ; world.queue_free(); await process_frame; return
	world.queue_free(); await process_frame
	print("PASS: phase3 16_player_traffic_integration")
	quit(0)
