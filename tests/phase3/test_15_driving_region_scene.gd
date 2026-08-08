extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var packed := load("res://scenes/world/proving_region.tscn") as PackedScene
	if packed == null: fail("proving-region scene must load"); return
	var world = packed.instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	if not world.has_method("get_driving_region_definition") or not world.has_method("get_navigation_service") or not world.has_method("get_traffic_manager"):
		fail("Phase 3 scene must expose driving-region/navigation/traffic accessors"); world.queue_free(); await process_frame; return
	var region = world.get_driving_region_definition()
	if region == null or not region.validate().is_empty(): fail("runtime driving-region definition must validate"); world.queue_free(); await process_frame; return
	var player = world.get_player_vehicle()
	if player == null or not player is VehicleController: fail("Phase 1 player vehicle must remain the free-roam player") ; world.queue_free(); await process_frame; return
	var phase3_environment := world.get_node_or_null("WorldRuntime/EnvironmentRoot/Phase3Environment")
	var presentation := world.get_node_or_null("WorldRuntime/RoadsRoot/Phase3Presentation")
	var traffic_root := world.get_node_or_null("WorldRuntime/TrafficRoot")
	if phase3_environment == null or presentation == null or traffic_root == null:
		fail("Phase 3 runtime must contain environment, road-presentation, and traffic roots"); world.queue_free(); await process_frame; return
	if world.get_node_or_null("WorldRuntime/EnvironmentRoot/Sun") == null or world.get_node_or_null("WorldRuntime/EnvironmentRoot/WorldEnvironment") == null:
		fail("static daytime lighting must remain present"); world.queue_free(); await process_frame; return
	if world.find_child("WeatherSystem", true, false) != null or world.find_child("DayNightSystem", true, false) != null:
		fail("Phase 3 must not introduce weather or day/night runtime systems"); world.queue_free(); await process_frame; return
	var manager: TrafficManager = world.get_traffic_manager()
	if manager == null or manager.active_count() <= 0: fail("free-roam scene must begin with basic civilian traffic") ; world.queue_free(); await process_frame; return
	world.queue_free(); await process_frame
	print("PASS: phase3 15_driving_region_scene")
	quit(0)
