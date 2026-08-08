class_name ProvingRegionDefinition
extends Resource

var grid: WorldGrid = WorldGrid.new()
var cells: Array[WorldCellDefinition] = []
var road_network: RoadNetwork = RoadNetwork.new()
var spawn_transform: Transform3D = Transform3D.IDENTITY
var roadside_test_zone_transform: Transform3D = Transform3D.IDENTITY
var spawn_surface_id: StringName = &"asphalt_dry"
var authored_cell_coords: Array[Vector2i] = []

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if grid == null:
		errors.append("proving region grid must not be null")
		return errors
	if road_network == null:
		errors.append("proving region road network must not be null")
	else:
		for error in road_network.validation_errors():
			errors.append("road network: %s" % error)
	var ids: Dictionary = {}
	var coords: Dictionary = {}
	for cell in cells:
		if cell == null:
			errors.append("cell definition must not be null")
			continue
		for error in cell.validation_errors(grid):
			errors.append("%s: %s" % [cell.id, error])
		if ids.has(cell.id):
			errors.append("duplicate cell id: %s" % cell.id)
		if coords.has(cell.coord):
			errors.append("duplicate cell coordinate: %s" % cell.coord)
		ids[cell.id] = true
		coords[cell.coord] = true
	if not SurfaceResolver.is_supported_id(spawn_surface_id):
		errors.append("spawn surface is unsupported: %s" % spawn_surface_id)
	for coord in authored_cell_coords:
		if not grid.is_valid_coord(coord):
			errors.append("authored cell is outside grid: %s" % coord)
	return errors

func cell_for_coord(coord: Vector2i) -> WorldCellDefinition:
	for cell in cells:
		if cell.coord == coord:
			return cell
	return null

func has_closed_loop(profile_ids: Array) -> bool:
	var adjacency: Dictionary = {}
	for segment in road_network.segments():
		if segment.profile_id not in profile_ids:
			continue
		if not adjacency.has(segment.start_junction_id):
			adjacency[segment.start_junction_id] = []
		if not adjacency.has(segment.end_junction_id):
			adjacency[segment.end_junction_id] = []
		adjacency[segment.start_junction_id].append(segment.end_junction_id)
		adjacency[segment.end_junction_id].append(segment.start_junction_id)
	var visited: Dictionary = {}
	for junction_id in adjacency.keys():
		if not visited.has(junction_id) and _has_cycle_from(junction_id, &"", adjacency, visited):
			return true
	return false

func _has_cycle_from(current: StringName, parent: StringName, adjacency: Dictionary, visited: Dictionary) -> bool:
	visited[current] = true
	for neighbor in adjacency.get(current, []):
		if not visited.has(neighbor):
			if _has_cycle_from(neighbor, current, adjacency, visited):
				return true
		elif neighbor != parent:
			return true
	return false
