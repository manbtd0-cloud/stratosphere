class_name WorldStreamingPolicy
extends RefCounted

func desired_cells(
	grid: WorldGrid,
	config: WorldStreamingConfig,
	observer_position: Vector3,
	observer_velocity: Vector3,
	resident_cells: Dictionary = {}
) -> Dictionary:
	if grid == null or config == null or not config.validation_errors().is_empty():
		return {"gameplay": [], "predictive": [], "visual": [], "keep_resident": []}
	var current := grid.world_to_coord(observer_position)
	if not grid.is_valid_coord(current):
		return {"gameplay": [], "predictive": [], "visual": [], "keep_resident": []}
	var gameplay_set := _square_set(grid, current, config.gameplay_radius_cells)
	var visual_set := _square_set(grid, current, config.visual_radius_cells)
	var predicted_position := observer_position + observer_velocity * config.predictive_lookahead_seconds
	var predicted := grid.world_to_coord(predicted_position)
	predicted.x = clampi(predicted.x, -grid.half_extent_cells, grid.half_extent_cells - 1)
	predicted.y = clampi(predicted.y, -grid.half_extent_cells, grid.half_extent_cells - 1)
	var predictive_set: Dictionary = {}
	for coord in _line_cells(current, predicted):
		if grid.is_valid_coord(coord):
			predictive_set[coord] = true
	for coord in grid.neighbors(predicted, config.gameplay_radius_cells):
		predictive_set[coord] = true
	predictive_set[predicted] = true
	var keep_set: Dictionary = {}
	var retain_radius := config.visual_radius_cells + config.unload_hysteresis_cells
	for coord in resident_cells.keys():
		if not coord is Vector2i or not grid.is_valid_coord(coord):
			continue
		if _chebyshev_distance(current, coord) <= retain_radius and not visual_set.has(coord):
			keep_set[coord] = true
	return {
		"gameplay": _sorted_coords(gameplay_set),
		"predictive": _sorted_coords(predictive_set),
		"visual": _sorted_coords(visual_set),
		"keep_resident": _sorted_coords(keep_set),
	}

func _square_set(grid: WorldGrid, center: Vector2i, radius: int) -> Dictionary:
	var result: Dictionary = {}
	for z in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var coord := Vector2i(x, z)
			if grid.is_valid_coord(coord):
				result[coord] = true
	return result

func _line_cells(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var steps := maxi(abs(finish.x - start.x), abs(finish.y - start.y))
	if steps == 0:
		return [start]
	for step in range(steps + 1):
		var t := float(step) / float(steps)
		var coord := Vector2i(
			roundi(lerpf(float(start.x), float(finish.x), t)),
			roundi(lerpf(float(start.y), float(finish.y), t))
		)
		if coord not in result:
			result.append(coord)
	return result

func _sorted_coords(values: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in values.keys():
		result.append(coord)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	return result

func _chebyshev_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(abs(a.x - b.x), abs(a.y - b.y))
