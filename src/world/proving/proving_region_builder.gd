class_name ProvingRegionBuilder
extends RefCounted

var _road_builder := RoadGeometryBuilder.new()

func build(definition: ProvingRegionDefinition) -> Node3D:
	if definition == null or not definition.validation_errors().is_empty():
		return null
	var world := Node3D.new()
	world.name = "ProvingRegionRuntime"

	var terrain_root := Node3D.new()
	terrain_root.name = "TerrainRoot"
	world.add_child(terrain_root)
	var stream_manager := WorldStreamManager.new()
	stream_manager.name = "WorldStreamManager"
	terrain_root.add_child(stream_manager)
	var backend := BuiltinTerrainBackend.new()
	var config := WorldStreamingConfig.new()
	var stream_errors := stream_manager.configure(definition.grid, backend, definition.cells, config)
	if not stream_errors.is_empty():
		world.free()
		return null
	stream_manager.update_observer(definition.spawn_transform.origin, Vector3.ZERO)

	var roads_root := Node3D.new()
	roads_root.name = "RoadsRoot"
	world.add_child(roads_root)
	var asphalt_material := _material(Color(0.075, 0.078, 0.082), 0.91)
	var dirt_material := _material(Color(0.24, 0.14, 0.075), 0.98)
	var gravel_material := _material(Color(0.27, 0.26, 0.24), 0.98)
	for segment in definition.road_network.segments():
		var profile := RoadProfile.for_id(segment.profile_id)
		var road_node := _road_builder.create_segment_node(segment, profile)
		road_node.position.y += 0.04
		var road_mesh := road_node.get_node_or_null("RoadSurface") as MeshInstance3D
		if road_mesh != null:
			road_mesh.material_override = dirt_material if segment.surface_id == &"dirt" else asphalt_material
		for shoulder_name in ["LeftShoulder", "RightShoulder"]:
			var shoulder_mesh := road_node.get_node_or_null(shoulder_name) as MeshInstance3D
			if shoulder_mesh != null:
				shoulder_mesh.material_override = dirt_material if profile.shoulder_surface_id == &"dirt" else gravel_material
		roads_root.add_child(road_node)
	_add_junction_patches(roads_root, definition, asphalt_material, dirt_material)

	var environment_root := Node3D.new()
	environment_root.name = "EnvironmentRoot"
	world.add_child(environment_root)
	_add_environment(environment_root)
	_add_roadside_cluster(environment_root, definition.roadside_test_zone_transform.origin)
	_add_surface_test_patches(environment_root)

	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.transform = definition.spawn_transform
	spawn.set_meta("surface_id", definition.spawn_surface_id)
	world.add_child(spawn)
	var roadside := Marker3D.new()
	roadside.name = "RoadsideTestZone"
	roadside.transform = definition.roadside_test_zone_transform
	world.add_child(roadside)
	return world

func _add_junction_patches(roads_root: Node3D, definition: ProvingRegionDefinition, asphalt_material: Material, dirt_material: Material) -> void:
	var patches := Node3D.new()
	patches.name = "JunctionPatches"
	roads_root.add_child(patches)
	for junction in definition.road_network.junctions():
		var connected := definition.road_network.connected_segments(junction.id)
		if connected.size() < 2:
			continue
		var radius := 5.0
		var surface_id: StringName = &"dirt"
		for segment in connected:
			var profile := RoadProfile.for_id(segment.profile_id)
			radius = maxf(radius, profile.road_width_m() * 0.5 + profile.shoulder_width_m + 1.5)
			if segment.surface_id != &"dirt":
				surface_id = &"asphalt_dry"
		var patch := Node3D.new()
		patch.name = "Patch_%s" % String(junction.id).replace(".", "_")
		patch.position = junction.position + Vector3(0, 0.055, 0)
		patch.set_meta("junction_id", junction.id)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(radius * 2.0, 0.08, radius * 2.0)
		var visual := MeshInstance3D.new()
		visual.name = "Surface"
		visual.mesh = mesh
		visual.material_override = dirt_material if surface_id == &"dirt" else asphalt_material
		patch.add_child(visual)
		var body := StaticBody3D.new()
		body.name = "Collision"
		body.set_meta("surface_id", surface_id)
		body.set_meta("junction_id", junction.id)
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		collision.shape = shape
		body.add_child(collision)
		patch.add_child(body)
		patches.add_child(patch)

func _add_environment(environment_root: Node3D) -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.16, 0.31, 0.52)
	sky_material.sky_horizon_color = Color(0.62, 0.72, 0.82)
	sky_material.ground_bottom_color = Color(0.07, 0.08, 0.055)
	sky_material.ground_horizon_color = Color(0.38, 0.41, 0.34)
	sky.sky_material = sky_material
	environment.sky = sky
	world_environment.environment = environment
	environment_root.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	environment_root.add_child(sun)

func _add_roadside_cluster(environment_root: Node3D, origin: Vector3) -> void:
	var cluster := Node3D.new()
	cluster.name = "RoadsideCluster"
	cluster.position = origin
	environment_root.add_child(cluster)
	_add_building_box(cluster, "ServiceBuilding", Vector3(26, 7, 14), Vector3(32, 3.5, 28), Color(0.31, 0.32, 0.31))
	_add_building_box(cluster, "Workshop", Vector3(18, 5, 12), Vector3(-24, 2.5, 32), Color(0.26, 0.23, 0.20))
	_add_building_box(cluster, "Canopy", Vector3(20, 0.7, 9), Vector3(5, 4.2, 18), Color(0.52, 0.53, 0.50))

func _add_surface_test_patches(environment_root: Node3D) -> void:
	var root := Node3D.new()
	root.name = "SurfaceTestPatches"
	environment_root.add_child(root)
	var specs := [
		["Gravel", &"gravel", Vector3(-260, 0.08, 80), Color(0.34, 0.31, 0.26)],
		["Dirt", &"dirt", Vector3(-180, 0.08, 80), Color(0.27, 0.15, 0.08)],
		["Grass", &"grass", Vector3(-100, 0.08, 80), Color(0.075, 0.20, 0.07)],
	]
	for spec in specs:
		var body := StaticBody3D.new()
		body.name = spec[0]
		body.position = spec[2]
		body.set_meta("surface_id", spec[1])
		body.set_meta("surface_test_patch", true)
		var size := Vector3(52.0, 0.16, 52.0)
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		collision.shape = shape
		body.add_child(collision)
		var mesh := BoxMesh.new()
		mesh.size = size
		var visual := MeshInstance3D.new()
		visual.name = "Mesh"
		visual.mesh = mesh
		visual.material_override = _material(spec[3], 0.96)
		body.add_child(visual)
		root.add_child(body)

func _add_building_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.set_meta("environment_prop", true)
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	visual.material_override = _material(color, 0.82)
	body.add_child(visual)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
