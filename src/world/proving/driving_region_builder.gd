class_name DrivingRegionBuilder
extends RefCounted

var _placement := DeterministicPlacementService.new()
var _cluster_builder := EnvironmentClusterBuilder.new()
var _road_presentation_builder := RoadPresentationBuilder.new()
var _terrain_sampler := BuiltinTerrainBackend.new()

func build(region: DrivingRegionDefinition) -> Node3D:
	if region == null or not region.validate().is_empty():
		return null
	var runtime := ProvingRegionBuilder.new().build(region.base_definition)
	if runtime == null:
		return null
	_build_environment(runtime, region)
	_build_road_presentation(runtime, region)
	_build_facility_hooks(runtime, region)
	return runtime

func _build_environment(runtime: Node3D, region: DrivingRegionDefinition) -> void:
	var environment_root := runtime.get_node_or_null("EnvironmentRoot") as Node3D
	if environment_root == null:
		return
	var phase3_root := Node3D.new()
	phase3_root.name = "Phase3Environment"
	environment_root.add_child(phase3_root)
	var grid := region.base_definition.grid
	for coord in region.authored_cell_coords:
		var cell_id := grid.coord_to_id(coord)
		var cell_node := Node3D.new()
		cell_node.name = "Cell_%s" % String(cell_id).replace(".", "_").replace("-", "m")
		cell_node.set_meta("cell_id", cell_id)
		var fingerprints := PackedStringArray()
		for zone in region.zones:
			if cell_id not in zone.cell_ids:
				continue
			var cluster := _cluster_for_zone(zone, cell_id, grid.coord_to_center(coord))
			if cluster != null:
				cell_node.add_child(cluster)
				fingerprints.append("%s:%s" % [zone.id, cluster.get_meta("transform_fingerprint", "")])
		fingerprints.sort()
		cell_node.set_meta("content_fingerprint", "|".join(fingerprints).sha256_text())
		phase3_root.add_child(cell_node)

func _cluster_for_zone(zone: EnvironmentZoneDefinition, cell_id: StringName, center: Vector3) -> MultiMeshInstance3D:
	var count := _zone_instance_count(zone.zone_class)
	if count <= 0:
		return null
	var extent := 215.0
	var bounds := AABB(Vector3(center.x - extent, 0.0, center.z - extent), Vector3(extent * 2.0, 1.0, extent * 2.0))
	var transforms := _placement.generate(zone, cell_id, StringName("phase3.%s" % zone.zone_class), bounds, count, _zone_spacing(zone.zone_class))
	if transforms.is_empty():
		return null
	for index in range(transforms.size()):
		var transform := transforms[index]
		transform.origin.y = _terrain_sampler.sample_height(transform.origin) + _zone_vertical_offset(zone.zone_class)
		transforms[index] = transform
	var mesh := _zone_mesh(zone.zone_class)
	var density := clampf(zone.density_multiplier, 0.1, 1.0)
	return _cluster_builder.build_cluster(StringName("environment.%s" % zone.id), cell_id, mesh, transforms, density)

func _zone_instance_count(zone_class: StringName) -> int:
	match zone_class:
		&"forest": return 28
		&"farmland": return 16
		&"countryside_open": return 12
		&"hill_rocky": return 14
		&"rural_settlement": return 9
		&"industrial_service": return 8
		&"highway_corridor": return 8
		&"dirt_trail_corridor": return 10
		&"scenic_overlook": return 5
	return 0

func _zone_spacing(zone_class: StringName) -> float:
	match zone_class:
		&"forest": return 16.0
		&"rural_settlement", &"industrial_service": return 28.0
		&"farmland": return 24.0
	return 22.0

func _zone_vertical_offset(zone_class: StringName) -> float:
	match zone_class:
		&"forest": return 3.5
		&"rural_settlement", &"industrial_service": return 2.5
		&"hill_rocky": return 1.2
		&"highway_corridor", &"dirt_trail_corridor": return 0.65
	return 0.5

func _zone_mesh(zone_class: StringName) -> Mesh:
	match zone_class:
		&"forest":
			var mesh := CylinderMesh.new(); mesh.top_radius = 0.45; mesh.bottom_radius = 0.75; mesh.height = 7.0; mesh.radial_segments = 6; mesh.material = _material(Color(0.10, 0.22, 0.08), 0.92); return mesh
		&"rural_settlement":
			var mesh := BoxMesh.new(); mesh.size = Vector3(7.0, 5.0, 9.0); mesh.material = _material(Color(0.46, 0.39, 0.31), 0.82); return mesh
		&"industrial_service":
			var mesh := BoxMesh.new(); mesh.size = Vector3(11.0, 5.0, 14.0); mesh.material = _material(Color(0.28, 0.30, 0.31), 0.74); return mesh
		&"hill_rocky":
			var mesh := SphereMesh.new(); mesh.radius = 1.8; mesh.height = 2.4; mesh.radial_segments = 8; mesh.rings = 4; mesh.material = _material(Color(0.32, 0.30, 0.27), 0.98); return mesh
		&"farmland":
			var mesh := BoxMesh.new(); mesh.size = Vector3(1.2, 1.0, 2.3); mesh.material = _material(Color(0.52, 0.42, 0.18), 0.95); return mesh
		&"highway_corridor":
			var mesh := BoxMesh.new(); mesh.size = Vector3(0.14, 1.3, 0.14); mesh.material = _material(Color(0.52, 0.54, 0.55), 0.66); return mesh
		&"dirt_trail_corridor":
			var mesh := SphereMesh.new(); mesh.radius = 0.55; mesh.height = 0.8; mesh.radial_segments = 6; mesh.rings = 3; mesh.material = _material(Color(0.25, 0.32, 0.16), 0.94); return mesh
		&"scenic_overlook":
			var mesh := BoxMesh.new(); mesh.size = Vector3(2.5, 1.0, 0.35); mesh.material = _material(Color(0.31, 0.27, 0.20), 0.90); return mesh
	var fallback := BoxMesh.new(); fallback.size = Vector3.ONE; fallback.material = _material(Color(0.26,0.34,0.20), 0.9); return fallback

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = roughness; return material

func _build_road_presentation(runtime: Node3D, region: DrivingRegionDefinition) -> void:
	var roads_root := runtime.get_node_or_null("RoadsRoot") as Node3D
	if roads_root == null: return
	var phase3_root := Node3D.new(); phase3_root.name = "Phase3Presentation"; roads_root.add_child(phase3_root)
	for segment in region.base_definition.road_network.segments():
		var profile := RoadProfile.for_id(segment.profile_id)
		if profile == null: continue
		var presentation := _road_presentation_builder.build_segment_presentation(segment, profile)
		if presentation != null: phase3_root.add_child(presentation)

func _build_facility_hooks(runtime: Node3D, region: DrivingRegionDefinition) -> void:
	var root := Node3D.new(); root.name = "FacilityHooks"; runtime.add_child(root)
	for facility_id in [&"garage", &"dealership"]:
		var marker := Marker3D.new(); marker.name = String(facility_id).capitalize(); marker.transform = region.facility_hooks[facility_id]; marker.set_meta("facility_id", facility_id); root.add_child(marker)
