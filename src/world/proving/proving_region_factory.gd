class_name ProvingRegionFactory
extends RefCounted

const ALL_PROFILES := [&"highway", &"rural_two_lane", &"hill_two_lane", &"service", &"dirt_trail"]

static func create() -> ProvingRegionDefinition:
	var definition := ProvingRegionDefinition.new()
	definition.grid = WorldGrid.new(512.0, 6)
	_build_cells(definition)
	_build_roads(definition)
	_assign_roads_to_cells(definition)
	definition.spawn_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-90.0)), Vector3(0.0, 1.25, 500.0))
	definition.spawn_surface_id = &"asphalt_dry"
	definition.roadside_test_zone_transform = Transform3D(Basis.IDENTITY, Vector3(150.0, 0.0, 50.0))
	return definition

static func _build_cells(definition: ProvingRegionDefinition) -> void:
	for z in range(-6, 6):
		for x in range(-6, 6):
			var cell := WorldCellDefinition.new()
			cell.coord = Vector2i(x, z)
			cell.id = definition.grid.coord_to_id(cell.coord)
			cell.terrain_backend_key = &"builtin"
			cell.surface_region_ids.append(&"surface.grass")
			cell.persistent_state_namespace = StringName("world.proving.%s" % cell.id)
			definition.cells.append(cell)

static func _build_roads(definition: ProvingRegionDefinition) -> void:
	var network := definition.road_network
	# Fast outer highway loop.
	_add_junction(network, &"junction.highway.nw", Vector3(-900, 0, 500), &"highway_merge")
	_add_junction(network, &"junction.highway.ne", Vector3(900, 0, 500), &"highway_merge")
	_add_junction(network, &"junction.highway.se", Vector3(900, 0, -550), &"highway_merge")
	_add_junction(network, &"junction.highway.sw", Vector3(-900, 0, -550), &"highway_merge")
	_add_segment(network, &"road.highway.north", &"junction.highway.nw", &"junction.highway.ne", &"highway", &"asphalt_dry", 140.0, [Vector3(-900,0,500), Vector3(0,0,500), Vector3(900,0,500)])
	_add_segment(network, &"road.highway.east", &"junction.highway.ne", &"junction.highway.se", &"highway", &"asphalt_dry", 130.0, [Vector3(900,0,500), Vector3(980,0,0), Vector3(900,0,-550)])
	_add_segment(network, &"road.highway.south", &"junction.highway.se", &"junction.highway.sw", &"highway", &"asphalt_dry", 140.0, [Vector3(900,0,-550), Vector3(0,0,-600), Vector3(-900,0,-550)])
	_add_segment(network, &"road.highway.west", &"junction.highway.sw", &"junction.highway.nw", &"highway", &"asphalt_dry", 130.0, [Vector3(-900,0,-550), Vector3(-980,0,0), Vector3(-900,0,500)])

	# Sweeping inner rural loop.
	_add_junction(network, &"junction.rural.0", Vector3(-600, 0, 250))
	_add_junction(network, &"junction.rural.1", Vector3(0, 0, 320), &"t_junction")
	_add_junction(network, &"junction.rural.2", Vector3(600, 0, 180))
	_add_junction(network, &"junction.rural.3", Vector3(450, 0, -260), &"t_junction")
	_add_junction(network, &"junction.rural.4", Vector3(-450, 0, -300), &"t_junction")
	_add_segment(network, &"road.rural.01", &"junction.rural.0", &"junction.rural.1", &"rural_two_lane", &"asphalt_dry", 90.0, [Vector3(-600,0,250), Vector3(-320,0,360), Vector3(0,0,320)])
	_add_segment(network, &"road.rural.12", &"junction.rural.1", &"junction.rural.2", &"rural_two_lane", &"asphalt_dry", 90.0, [Vector3(0,0,320), Vector3(330,0,350), Vector3(600,0,180)])
	_add_segment(network, &"road.rural.23", &"junction.rural.2", &"junction.rural.3", &"rural_two_lane", &"asphalt_dry", 80.0, [Vector3(600,0,180), Vector3(680,0,-40), Vector3(450,0,-260)])
	_add_segment(network, &"road.rural.34", &"junction.rural.3", &"junction.rural.4", &"rural_two_lane", &"asphalt_dry", 85.0, [Vector3(450,0,-260), Vector3(0,0,-390), Vector3(-450,0,-300)])
	_add_segment(network, &"road.rural.40", &"junction.rural.4", &"junction.rural.0", &"rural_two_lane", &"asphalt_dry", 80.0, [Vector3(-450,0,-300), Vector3(-680,0,-40), Vector3(-600,0,250)])

	# Technical hill branch.
	_add_junction(network, &"junction.hill.1", Vector3(-650, 38, -620))
	_add_junction(network, &"junction.hill.2", Vector3(-350, 88, -850))
	_add_segment(network, &"road.hill.climb_a", &"junction.rural.4", &"junction.hill.1", &"hill_two_lane", &"asphalt_dry", 65.0, [Vector3(-450,0,-300), Vector3(-730,18,-450), Vector3(-650,38,-620)])
	_add_segment(network, &"road.hill.climb_b", &"junction.hill.1", &"junction.hill.2", &"hill_two_lane", &"asphalt_dry", 55.0, [Vector3(-650,38,-620), Vector3(-500,64,-760), Vector3(-350,88,-850)])

	# Roadside/service branch and loose-surface cut-through.
	_add_junction(network, &"junction.service.zone", Vector3(150, 0, 50), &"t_junction")
	_add_segment(network, &"road.service.zone", &"junction.rural.1", &"junction.service.zone", &"service", &"asphalt_dry", 45.0, [Vector3(0,0,320), Vector3(80,0,180), Vector3(150,0,50)])
	_add_segment(network, &"road.dirt.cutthrough", &"junction.service.zone", &"junction.rural.3", &"dirt_trail", &"dirt", 40.0, [Vector3(150,0,50), Vector3(280,2,-80), Vector3(450,0,-260)])

static func _add_junction(network: RoadNetwork, id: StringName, position: Vector3, junction_class: StringName = &"endpoint") -> void:
	var junction := RoadJunction.new()
	junction.id = id
	junction.position = position
	junction.junction_class = junction_class
	var error := network.add_junction(junction)
	assert(error == OK, "failed to add proving-region junction %s" % id)

static func _add_segment(network: RoadNetwork, id: StringName, start_id: StringName, end_id: StringName, profile_id: StringName, surface_id: StringName, speed_limit_kph: float, points: Array[Vector3]) -> void:
	var segment := RoadSegment.new()
	segment.id = id
	segment.start_junction_id = start_id
	segment.end_junction_id = end_id
	segment.profile_id = profile_id
	segment.surface_id = surface_id
	segment.speed_limit_kph = speed_limit_kph
	segment.centerline = _curve_from_points(points)
	var error := network.add_segment(segment)
	assert(error == OK, "failed to add proving-region road %s" % id)

static func _curve_from_points(points: Array[Vector3]) -> Curve3D:
	var curve := Curve3D.new()
	for point in points:
		curve.add_point(point)
	for i in range(points.size()):
		var previous: Vector3 = points[maxi(i - 1, 0)]
		var next: Vector3 = points[mini(i + 1, points.size() - 1)]
		var tangent := (next - previous) * 0.18
		if i > 0:
			curve.set_point_in(i, -tangent)
		if i < points.size() - 1:
			curve.set_point_out(i, tangent)
	return curve

static func _assign_roads_to_cells(definition: ProvingRegionDefinition) -> void:
	var sampler := RoadSplineSampler.new()
	var authored: Dictionary = {}
	for segment in definition.road_network.segments():
		for sample in sampler.sample(segment, 64.0):
			var coord := definition.grid.world_to_coord(sample.position)
			if not definition.grid.is_valid_coord(coord):
				continue
			authored[coord] = true
			var cell := definition.cell_for_coord(coord)
			if cell == null:
				continue
			if segment.id not in cell.road_segment_ids:
				cell.road_segment_ids.append(segment.id)
			var surface_region := StringName("surface.%s" % segment.surface_id)
			if surface_region not in cell.surface_region_ids:
				cell.surface_region_ids.append(surface_region)
	definition.authored_cell_coords.clear()
	for coord in authored.keys():
		definition.authored_cell_coords.append(coord)
	definition.authored_cell_coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	var roadside_coord := definition.grid.world_to_coord(Vector3(150, 0, 50))
	var roadside_cell := definition.cell_for_coord(roadside_coord)
	if roadside_cell != null:
		roadside_cell.environment_group_ids.append(&"environment.roadside_test_zone")
