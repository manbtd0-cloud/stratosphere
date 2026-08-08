class_name DrivingRegionFactory
extends RefCounted

static func create() -> DrivingRegionDefinition:
	var region := DrivingRegionDefinition.new()
	region.base_definition = ProvingRegionFactory.create()
	_connect_highway_to_rural(region.base_definition.road_network)
	# 5 x 4 contiguous cells = 20 * 0.512^2 km² = 5.24288 km².
	for z in range(-2, 2):
		for x in range(-2, 3):
			region.authored_cell_coords.append(Vector2i(x, z))
	var grid := region.base_definition.grid
	region.zones = [
		_zone(&"zone.countryside.central", &"countryside_open", grid, [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]),
		_zone(&"zone.farmland.east", &"farmland", grid, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)]),
		_zone(&"zone.forest.west", &"forest", grid, [Vector2i(-2, -1), Vector2i(-2, 0), Vector2i(-1, -1)]),
		_zone(&"zone.hill.southwest", &"hill_rocky", grid, [Vector2i(-2, -2), Vector2i(-1, -2)]),
		_zone(&"zone.settlement.center", &"rural_settlement", grid, [Vector2i(0, 0), Vector2i(0, 1)]),
		_zone(&"zone.industrial.southeast", &"industrial_service", grid, [Vector2i(1, -1), Vector2i(2, -1)]),
		_zone(&"zone.highway.north", &"highway_corridor", grid, [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]),
		_zone(&"zone.dirt.south", &"dirt_trail_corridor", grid, [Vector2i(0, -1), Vector2i(1, -1)]),
		_zone(&"zone.overlook.hill", &"scenic_overlook", grid, [Vector2i(-1, -2)]),
	]
	region.facility_hooks[&"garage"] = Transform3D(Basis.IDENTITY, Vector3(150.0, 0.0, 50.0))
	region.facility_hooks[&"dealership"] = Transform3D(Basis.IDENTITY, Vector3(225.0, 0.0, 85.0))
	return region

static func _zone(id: StringName, zone_class: StringName, grid: WorldGrid, coords: Array[Vector2i]) -> EnvironmentZoneDefinition:
	var zone := EnvironmentZoneDefinition.new()
	zone.id = id
	zone.zone_class = zone_class
	for coord in coords:
		zone.cell_ids.append(grid.coord_to_id(coord))
	match zone_class:
		&"forest":
			zone.density_multiplier = 1.25
			zone.traffic_density_multiplier = 0.55
			zone.vegetation_palette_ids = [&"vegetation.tree_mixed", &"vegetation.shrub_dense"]
		&"farmland":
			zone.density_multiplier = 0.55
			zone.traffic_density_multiplier = 0.75
		&"highway_corridor":
			zone.density_multiplier = 0.30
			zone.traffic_density_multiplier = 1.35
		&"dirt_trail_corridor":
			zone.traffic_density_multiplier = 0.0
		&"rural_settlement":
			zone.traffic_density_multiplier = 1.0
		&"hill_rocky":
			zone.traffic_density_multiplier = 0.45
	return zone

static func _connect_highway_to_rural(network: RoadNetwork) -> void:
	if network == null or network.get_segment(&"road.connector.highway_rural") != null:
		return
	var segment := RoadSegment.new()
	segment.id = &"road.connector.highway_rural"
	segment.start_junction_id = &"junction.highway.ne"
	segment.end_junction_id = &"junction.rural.2"
	segment.profile_id = &"rural_two_lane"
	segment.surface_id = &"asphalt_dry"
	segment.speed_limit_kph = 80.0
	segment.centerline = Curve3D.new()
	segment.centerline.add_point(Vector3(900, 0, 500))
	segment.centerline.add_point(Vector3(820, 0, 350), Vector3(-30, 0, 20), Vector3(30, 0, -20))
	segment.centerline.add_point(Vector3(600, 0, 180))
	assert(network.add_segment(segment) == OK)
