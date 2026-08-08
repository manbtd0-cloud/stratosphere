extends SceneTree

const EXPECTED_BOOTSTRAP := "res://src/bootstrap/main.tscn"
const PROVING_SCENE := "res://scenes/world/proving_region.tscn"

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	if load(PROVING_SCENE) == null:
		fail("Phase 2 proving-region scene must exist standalone")
		return
	if ProjectSettings.get_setting("application/run/main_scene") != EXPECTED_BOOTSTRAP:
		fail("project bootstrap main-scene contract must remain intact")
		return
	var bootstrap_scene := load(EXPECTED_BOOTSTRAP) as PackedScene
	if bootstrap_scene == null:
		fail("bootstrap scene must load")
		return
	var bootstrap = bootstrap_scene.instantiate()
	root.add_child(bootstrap)
	await process_frame
	await physics_frame
	var world = bootstrap.get_node_or_null("ProvingRegion")
	if world == null:
		fail("bootstrap must launch the Phase 2 proving region")
		bootstrap.queue_free(); await process_frame
		return
	if not world.has_method("get_player_vehicle") or not world.has_method("get_stream_manager"):
		fail("world scene must expose player and stream-manager accessors")
		bootstrap.queue_free(); await process_frame
		return
	var player: VehicleController = world.get_player_vehicle()
	var manager: WorldStreamManager = world.get_stream_manager()
	if player == null or manager == null:
		fail("world scene must instantiate player vehicle and streaming manager")
		bootstrap.queue_free(); await process_frame
		return
	var environment_root: Node = world.get_node_or_null("WorldRuntime/EnvironmentRoot")
	if environment_root == null or environment_root.get_node_or_null("Sun") == null or environment_root.get_node_or_null("WorldEnvironment") == null:
		fail("standalone world scene must contain deterministic lighting/environment")
		bootstrap.queue_free(); await process_frame
		return
	if manager.loaded_cell_count() <= 0:
		fail("world must begin with streamed terrain resident")
		bootstrap.queue_free(); await process_frame
		return
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 0.5, player.global_position + Vector3.DOWN * 5.0)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		fail("player spawn must be above world collision")
		bootstrap.queue_free(); await process_frame
		return
	if SurfaceResolver.surface_id_from_collider(hit.get("collider")) != &"asphalt_dry":
		fail("player spawn must resolve to asphalt road collision")
		bootstrap.queue_free(); await process_frame
		return
	bootstrap.queue_free()
	await process_frame
	print("PASS: phase2 13_world_scene_contract")
	quit(0)
