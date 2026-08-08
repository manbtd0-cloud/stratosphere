class_name DrivingRegionDefinition
extends Resource

var base_definition: ProvingRegionDefinition
var authored_cell_coords: Array[Vector2i] = []
var zones: Array[EnvironmentZoneDefinition] = []
var facility_hooks: Dictionary = {}

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if base_definition == null or base_definition.grid == null:
		errors.append("base proving region must exist")
		return errors
	if authored_cell_coords.size() < 16 or authored_cell_coords.size() > 22:
		errors.append("authored footprint must contain 16-22 cells")
	var seen_coords: Dictionary = {}
	for coord in authored_cell_coords:
		if not base_definition.grid.is_valid_coord(coord):
			errors.append("authored coordinate outside grid: %s" % coord)
		if seen_coords.has(coord):
			errors.append("duplicate authored coordinate: %s" % coord)
		seen_coords[coord] = true
	if not is_authored_connected():
		errors.append("authored footprint must be connected")
	var zone_ids: Dictionary = {}
	var classes: Dictionary = {}
	for zone in zones:
		if zone == null:
			errors.append("environment zone must not be null")
			continue
		for error in zone.validate():
			errors.append("zone %s: %s" % [zone.id, error])
		if zone_ids.has(zone.id):
			errors.append("duplicate environment zone id: %s" % zone.id)
		zone_ids[zone.id] = true
		classes[zone.zone_class] = true
		for cell_id in zone.cell_ids:
			var coord := base_definition.grid.id_to_coord(cell_id)
			if coord == WorldGrid.INVALID_COORD:
				errors.append("zone %s references invalid cell %s" % [zone.id, cell_id])
	for required in EnvironmentZoneDefinition.ALLOWED_CLASSES:
		if not classes.has(required):
			errors.append("missing environment zone class: %s" % required)
	for facility_id in [&"garage", &"dealership"]:
		if not facility_hooks.has(facility_id):
			errors.append("missing facility hook: %s" % facility_id)
			continue
		var transform = facility_hooks[facility_id]
		if not transform is Transform3D or not (transform as Transform3D).origin.is_finite():
			errors.append("invalid facility hook: %s" % facility_id)
	return errors

func is_authored_connected() -> bool:
	if authored_cell_coords.is_empty():
		return false
	var remaining: Dictionary = {}
	for coord in authored_cell_coords:
		remaining[coord] = true
	var queue: Array[Vector2i] = [authored_cell_coords[0]]
	var visited: Dictionary = {}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if visited.has(current):
			continue
		visited[current] = true
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + offset
			if remaining.has(next) and not visited.has(next):
				queue.append(next)
	return visited.size() == remaining.size()
