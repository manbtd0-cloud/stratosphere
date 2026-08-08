class_name DrivingWorldProbe
extends RefCounted

func run() -> Dictionary:
	var region: DrivingRegionDefinition = DrivingRegionFactory.create()
	if region == null or not region.validate().is_empty(): return {}
	var navigation_graph: NavigationGraph = NavigationGraphBuilder.new().build(region.base_definition.road_network)
	var navigation_service: NavigationService = NavigationService.new(navigation_graph)
	var navigation_route: Array[StringName] = navigation_service.find_route(&"junction.highway.ne", &"junction.hill.2")
	var lane_graph: TrafficLaneGraph = TrafficLaneGraphBuilder.new().build(region.base_definition.road_network, region.base_definition.grid)
	if navigation_graph == null or lane_graph == null: return {}
	var stream_evidence: Dictionary = _stream_evidence(region)
	var traffic_evidence: Dictionary = _traffic_evidence(lane_graph)
	var environment_fingerprint: String = _environment_fingerprint(region)
	var checksum_source: String = JSON.stringify({
		"stream": stream_evidence,
		"traffic": traffic_evidence,
		"environment": environment_fingerprint,
		"lanes": lane_graph.fingerprint(),
		"navigation_route": navigation_route,
	})
	return {
		"authored_cells": region.authored_cell_coords.size(),
		"route_steps": stream_evidence.route_steps,
		"predictive_steps": stream_evidence.predictive_steps,
		"max_gameplay_cells": stream_evidence.max_gameplay_cells,
		"max_visual_cells": stream_evidence.max_visual_cells,
		"max_predictive_cells": stream_evidence.max_predictive_cells,
		"max_keep_resident_cells": stream_evidence.max_keep_resident_cells,
		"traffic_candidates": traffic_evidence.count,
		"duplicate_traffic_candidates": traffic_evidence.duplicate,
		"navigation_edges": navigation_graph.edge_ids().size(),
		"navigation_route_edges": navigation_route.size(),
		"lane_graph_fingerprint": lane_graph.fingerprint(),
		"environment_fingerprint": environment_fingerprint,
		"checksum": checksum_source.sha256_text(),
	}

func _stream_evidence(region: DrivingRegionDefinition) -> Dictionary:
	var route := [
		Vector3(-1030,0,500), Vector3(-510,0,500), Vector3(-10,0,500), Vector3(510,0,500),
		Vector3(900,0,500), Vector3(600,0,180), Vector3(450,0,-260), Vector3(0,0,-300),
		Vector3(-450,0,-300), Vector3(-650,38,-620), Vector3(-350,88,-850),
	]
	var policy: WorldStreamingPolicy = WorldStreamingPolicy.new()
	var config: WorldStreamingConfig = WorldStreamingConfig.new()
	var residents: Dictionary = {}
	var max_gameplay := 0
	var max_visual := 0
	var max_predictive := 0
	var max_keep := 0
	var predictive_steps := 0
	for index in range(route.size()):
		var direction := Vector3.FORWARD
		if index < route.size() - 1: direction = (route[index + 1] - route[index]).normalized()
		elif index > 0: direction = (route[index] - route[index - 1]).normalized()
		var desired: Dictionary = policy.desired_cells(region.base_definition.grid, config, route[index], direction * 180.0, residents)
		max_gameplay = maxi(max_gameplay, desired.gameplay.size())
		max_visual = maxi(max_visual, desired.visual.size())
		max_predictive = maxi(max_predictive, desired.predictive.size())
		max_keep = maxi(max_keep, desired.keep_resident.size())
		var gameplay: Dictionary = {}; for coord in desired.gameplay: gameplay[coord] = true
		var ahead := false
		for coord in desired.predictive:
			if not gameplay.has(coord): ahead = true; break
		if ahead: predictive_steps += 1
		residents.clear()
		for key in ["gameplay", "visual", "predictive", "keep_resident"]:
			for coord in desired[key]: residents[coord] = true
	return {"route_steps": route.size(), "predictive_steps": predictive_steps, "max_gameplay_cells": max_gameplay, "max_visual_cells": max_visual, "max_predictive_cells": max_predictive, "max_keep_resident_cells": max_keep}

func _traffic_evidence(lane_graph: TrafficLaneGraph) -> Dictionary:
	var spawner: TrafficSpawner = TrafficSpawner.new()
	var player: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0,0,500))
	var occupied: Array = []
	var fingerprints := PackedStringArray()
	for _index in range(12):
		var candidate: TrafficSpawnCandidate = spawner.choose_candidate(lane_graph, player, occupied)
		if candidate == null: break
		occupied.append(candidate.position)
		fingerprints.append(candidate.fingerprint())
	var seen: Dictionary = {}
	var duplicate := false
	for fingerprint in fingerprints:
		if seen.has(fingerprint): duplicate = true
		seen[fingerprint] = true
	fingerprints.sort()
	return {"count": fingerprints.size(), "duplicate": duplicate, "fingerprints": fingerprints}

func _environment_fingerprint(region: DrivingRegionDefinition) -> String:
	var placement: DeterministicPlacementService = DeterministicPlacementService.new()
	var parts := PackedStringArray()
	var grid: WorldGrid = region.base_definition.grid
	for zone in region.zones:
		for cell_id in zone.cell_ids:
			var coord: Vector2i = grid.id_to_coord(cell_id)
			if coord == WorldGrid.INVALID_COORD: continue
			var center: Vector3 = grid.coord_to_center(coord)
			var bounds: AABB = AABB(Vector3(center.x - 180.0, 0.0, center.z - 180.0), Vector3(360.0, 1.0, 360.0))
			var transforms: Array[Transform3D] = placement.generate(zone, cell_id, &"phase3.probe", bounds, 5, 30.0)
			for transform in transforms:
				parts.append("%s|%s|%.3f|%.3f" % [zone.id, cell_id, transform.origin.x, transform.origin.z])
	parts.sort()
	return "|".join(parts).sha256_text()
