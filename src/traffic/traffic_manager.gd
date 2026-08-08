class_name TrafficManager
extends Node3D

var _graph: TrafficLaneGraph
var _definitions: Array[TrafficVehicleDefinition] = []
var _target_count: int = 12
var _max_active: int = 20
var _agents: Dictionary = {}
var _cell_by_id: Dictionary = {}
var _spawn_serial: int = 0
var _spawner := TrafficSpawner.new()
var _policy := TrafficSimulationPolicy.new()
var _configured: bool = false

func configure(graph: TrafficLaneGraph, definitions: Array[TrafficVehicleDefinition], target_count: int = 12, max_active: int = 20) -> PackedStringArray:
	var errors := PackedStringArray()
	if graph == null:
		errors.append("traffic lane graph must not be null")
	else:
		for error in graph.validation_errors(): errors.append(error)
	if definitions.is_empty():
		errors.append("at least one traffic vehicle definition is required")
	for definition in definitions:
		if definition == null:
			errors.append("traffic vehicle definition must not be null")
			continue
		for error in definition.validation_errors(): errors.append(error)
	if max_active <= 0: errors.append("max active traffic must be positive")
	if target_count < 0 or target_count > max_active: errors.append("traffic target must be within max-active budget")
	if not _policy.validation_errors().is_empty():
		for error in _policy.validation_errors(): errors.append(error)
	if not errors.is_empty(): return errors
	clear_all()
	_graph = graph
	_definitions = definitions.duplicate()
	_target_count = target_count
	_max_active = max_active
	_configured = true
	return errors

func spawn_to_target(player_transform: Transform3D, density_multiplier: float = 1.0) -> void:
	if not _configured: return
	var desired := desired_count_for_density(density_multiplier)
	var attempts := 0
	var max_attempts := maxi(desired * 6, 12)
	while active_count() < desired and attempts < max_attempts:
		attempts += 1
		var occupied: Array = []
		for agent in _agents.values():
			if is_instance_valid(agent): occupied.append((agent as TrafficAgent).position)
		var candidate := _spawner.choose_candidate(_graph, player_transform, occupied)
		if candidate == null: break
		var lane := _graph.get_lane(candidate.lane_id)
		if lane == null: break
		var definition := _definitions[_spawn_serial % _definitions.size()]
		var agent := TrafficAgent.new()
		var errors := agent.configure(definition, lane)
		if not errors.is_empty():
			agent.free()
			break
		_spawn_serial += 1
		agent.traffic_id = StringName("traffic.agent.%06d" % _spawn_serial)
		agent.name = "TrafficAgent_%06d" % _spawn_serial
		agent.position = candidate.position + Vector3.UP * 0.65
		agent.basis = Basis.looking_at(candidate.forward, Vector3.UP)
		_attach_development_body(agent, definition)
		var level := _policy.level_for(agent.traffic_id, candidate.distance_to_player_m)
		agent.set_simulation_level(level)
		if register_existing(agent, candidate.cell_id) != OK:
			agent.free()
			break

func desired_count_for_density(density_multiplier: float) -> int:
	return clampi(roundi(float(_target_count) * maxf(density_multiplier, 0.0)), 0, _max_active)

func register_existing(agent: TrafficAgent, cell_id: StringName) -> Error:
	if agent == null or agent.traffic_id.is_empty() or cell_id.is_empty(): return ERR_INVALID_PARAMETER
	if _agents.has(agent.traffic_id): return ERR_ALREADY_EXISTS
	_agents[agent.traffic_id] = agent
	_cell_by_id[agent.traffic_id] = cell_id
	if agent.get_parent() == null:
		add_child(agent)
	return OK

func reconcile_loaded_cells(loaded_cell_ids: PackedStringArray) -> void:
	var loaded: Dictionary = {}
	for cell_id in loaded_cell_ids: loaded[StringName(cell_id)] = true
	var to_remove: Array[StringName] = []
	for traffic_id in active_ids():
		var cell_id: StringName = _cell_by_id.get(traffic_id, &"")
		if not loaded.has(cell_id): to_remove.append(traffic_id)
	for traffic_id in to_remove: _remove_agent(traffic_id)

func update_simulation_levels(player_position: Vector3) -> void:
	for traffic_id in active_ids():
		var agent := agent_for_id(traffic_id)
		if agent == null: continue
		var distance := agent.position.distance_to(player_position)
		agent.set_simulation_level(_policy.level_for(traffic_id, distance, agent.simulation_level))

func active_count() -> int:
	return _agents.size()

func active_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for traffic_id in _agents.keys(): result.append(String(traffic_id))
	result.sort()
	return result

func agent_for_id(traffic_id: StringName) -> TrafficAgent:
	return _agents.get(traffic_id) as TrafficAgent

func cell_for_agent(traffic_id: StringName) -> StringName:
	return _cell_by_id.get(traffic_id, &"")

func clear_all() -> void:
	var ids: Array[StringName] = []
	for raw_id in _agents.keys(): ids.append(raw_id)
	for traffic_id in ids: _remove_agent(traffic_id)
	_agents.clear()
	_cell_by_id.clear()

func _remove_agent(traffic_id: StringName) -> void:
	if not _agents.has(traffic_id): return
	var agent := _agents[traffic_id] as TrafficAgent
	_agents.erase(traffic_id)
	_cell_by_id.erase(traffic_id)
	if agent != null and is_instance_valid(agent):
		if agent.is_inside_tree(): agent.queue_free()
		else: agent.free()

func _attach_development_body(agent: TrafficAgent, definition: TrafficVehicleDefinition) -> void:
	var shape := BoxShape3D.new()
	shape.size = definition.dimensions_m
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	agent.add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = definition.dimensions_m
	var material := StandardMaterial3D.new()
	var hue_seed := float(abs(String(definition.id).hash()) % 1000) / 1000.0
	material.albedo_color = Color.from_hsv(hue_seed, 0.38, 0.62)
	material.roughness = 0.48
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.name = "DevelopmentBody"
	visual.mesh = mesh
	agent.add_child(visual)
