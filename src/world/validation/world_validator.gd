class_name WorldValidator
extends RefCounted

static func validate(definition: ProvingRegionDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	if definition == null:
		errors.append("proving region definition must not be null")
		return errors
	for error in definition.validation_errors():
		errors.append(error)
	if definition.grid == null or definition.road_network == null:
		return errors
	var road_ids: Dictionary = {}
	for segment in definition.road_network.segments():
		road_ids[segment.id] = true
	for cell in definition.cells:
		if cell == null:
			continue
		for road_id in cell.road_segment_ids:
			if not road_ids.has(road_id):
				errors.append("cell %s references unknown road %s" % [cell.id, road_id])
		for region_id in cell.surface_region_ids:
			var text := String(region_id)
			if text.begins_with("surface."):
				var surface_id := StringName(text.trim_prefix("surface."))
				if not SurfaceResolver.is_supported_id(surface_id):
					errors.append("cell %s references unsupported surface region %s" % [cell.id, region_id])
	var authored: Dictionary = {}
	for coord in definition.authored_cell_coords:
		if authored.has(coord):
			errors.append("duplicate authored cell coordinate: %s" % coord)
		authored[coord] = true
	return _deduplicate(errors)

static func _deduplicate(values: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value):
			continue
		seen[value] = true
		result.append(value)
	return result
