extends SceneTree

static func simulate(definition: ProvingRegionDefinition) -> Dictionary:
	if definition == null or definition.grid == null:
		return {}
	var config := WorldStreamingConfig.new()
	var policy := WorldStreamingPolicy.new()
	var route: Array[Vector3] = [
		Vector3(-2500, 0, 500), Vector3(-1800, 0, 500), Vector3(-1000, 0, 500),
		Vector3(-200, 0, 500), Vector3(600, 0, 500), Vector3(1400, 0, 500),
		Vector3(2200, 0, 500), Vector3(2500, 0, -200), Vector3(2200, 0, -900),
		Vector3(1400, 0, -1400), Vector3(600, 0, -1900), Vector3(-200, 0, -2300),
		Vector3(-1000, 0, -2300), Vector3(-1800, 0, -1900), Vector3(-2400, 0, -1000),
	]
	var max_gameplay := 0
	var max_visual := 0
	var max_predictive := 0
	var max_keep_resident := 0
	var predictive_forward_steps := 0
	var residents: Dictionary = {}
	var fingerprint := ""
	for i in range(route.size()):
		var position := route[i]
		var next_position := route[mini(i + 1, route.size() - 1)]
		if i == route.size() - 1:
			next_position = route[i] + Vector3(95, 0, 0)
		var direction := (next_position - position).normalized()
		var velocity := direction * 95.0
		var desired := policy.desired_cells(definition.grid, config, position, velocity, residents)
		max_gameplay = maxi(max_gameplay, desired.gameplay.size())
		max_visual = maxi(max_visual, desired.visual.size())
		max_predictive = maxi(max_predictive, desired.predictive.size())
		max_keep_resident = maxi(max_keep_resident, desired.keep_resident.size())
		var current := definition.grid.world_to_coord(position)
		var has_forward_prediction := false
		for coord in desired.predictive:
			if coord == current:
				continue
			var to_cell := definition.grid.coord_to_center(coord) - position
			to_cell.y = 0.0
			if to_cell.length_squared() > 0.001 and to_cell.normalized().dot(velocity.normalized()) > 0.15:
				has_forward_prediction = true
				break
		if has_forward_prediction:
			predictive_forward_steps += 1
		residents.clear()
		for key in ["visual", "predictive", "gameplay", "keep_resident"]:
			for coord in desired[key]:
				residents[coord] = true
		fingerprint += "%d:%s|g=%s|p=%s|v=%s|k=%s;" % [
			i, current, desired.gameplay, desired.predictive, desired.visual, desired.keep_resident
		]
	return {
		"route_steps": route.size(),
		"max_gameplay_cells": max_gameplay,
		"max_visual_cells": max_visual,
		"max_predictive_cells": max_predictive,
		"max_keep_resident_cells": max_keep_resident,
		"predictive_forward_steps": predictive_forward_steps,
		"checksum": fingerprint.sha256_text(),
	}

func _init() -> void:
	var result := simulate(ProvingRegionFactory.create())
	if result.is_empty():
		push_error("WORLD_STREAM_RESULT failed")
		quit(1)
		return
	print("WORLD_STREAM_RESULT route_steps=%d max_gameplay=%d max_visual=%d max_predictive=%d max_keep=%d predictive_forward_steps=%d checksum=%s" % [
		result.route_steps,
		result.max_gameplay_cells,
		result.max_visual_cells,
		result.max_predictive_cells,
		result.max_keep_resident_cells,
		result.predictive_forward_steps,
		result.checksum,
	])
	quit(0)
