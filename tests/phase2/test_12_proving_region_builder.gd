extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)

func _init() -> void:
	var builder_script = load("res://src/world/proving/proving_region_builder.gd")
	if builder_script == null:
		fail("ProvingRegionBuilder script must exist")
		return
	var definition := ProvingRegionFactory.create()
	var builder = builder_script.new()
	var world: Node3D = builder.build(definition)
	if world == null:
		fail("builder must return a world root")
		return
	var terrain_root := world.get_node_or_null("TerrainRoot") as Node3D
	var roads_root := world.get_node_or_null("RoadsRoot") as Node3D
	var environment_root := world.get_node_or_null("EnvironmentRoot") as Node3D
	var stream_manager := world.get_node_or_null("TerrainRoot/WorldStreamManager") as WorldStreamManager
	if terrain_root == null or roads_root == null or environment_root == null or stream_manager == null:
		fail("builder must create terrain, road, environment, and stream-manager roots")
		world.free()
		return
	if world.get_node_or_null("PlayerSpawn") == null or world.get_node_or_null("RoadsideTestZone") == null:
		fail("builder must expose spawn and roadside test-zone markers")
		world.free()
		return
	if stream_manager.loaded_cell_count() <= 0 or stream_manager.loaded_cell_count() > 65:
		fail("builder must seed a bounded streamed terrain neighborhood")
		world.free()
		return
	var road_nodes := 0
	for child in roads_root.get_children():
		if child.has_meta("road_segment_id"):
			road_nodes += 1
			var collision := child.get_node_or_null("RoadCollision") as StaticBody3D
			if collision == null or not SurfaceResolver.is_supported_id(collision.get_meta("surface_id", &"")):
				fail("generated road node missing valid collision surface metadata")
				world.free()
				return
	if road_nodes != definition.road_network.segments().size():
		fail("every authoritative road segment must generate one road node")
		world.free()
		return
	if roads_root.get_node_or_null("JunctionPatches") == null:
		fail("explicit junction patches must be present")
		world.free()
		return
	if environment_root.get_node_or_null("RoadsideCluster") == null:
		fail("small roadside built-up test cluster must exist")
		world.free()
		return
	if environment_root.get_node_or_null("Sun") == null or environment_root.get_node_or_null("WorldEnvironment") == null:
		fail("deterministic sun and world environment must exist")
		world.free()
		return
	world.free()
	print("PASS: phase2 12_proving_region_builder")
	quit(0)
