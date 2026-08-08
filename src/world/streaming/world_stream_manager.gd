class_name WorldStreamManager
extends Node3D

signal cell_loaded(cell_id: StringName, cell_node: Node3D)
signal cell_unloaded(cell_id: StringName)

var _grid: WorldGrid
var _backend: TerrainBackendAdapter
var _config: WorldStreamingConfig
var _definitions_by_coord: Dictionary = {}
var _loaded_by_coord: Dictionary = {}
var _policy := WorldStreamingPolicy.new()
var _configured := false

func configure(
	grid: WorldGrid,
	backend: TerrainBackendAdapter,
	definitions: Array[WorldCellDefinition],
	config: WorldStreamingConfig
) -> PackedStringArray:
	var errors := PackedStringArray()
	_clear_loaded()
	_definitions_by_coord.clear()
	_configured = false
	if grid == null:
		errors.append("world grid must not be null")
	if backend == null:
		errors.append("terrain backend must not be null")
	if config == null:
		errors.append("streaming config must not be null")
	elif not config.validation_errors().is_empty():
		for error in config.validation_errors():
			errors.append(error)
	if not errors.is_empty():
		return errors
	var ids: Dictionary = {}
	for definition in definitions:
		if definition == null:
			errors.append("cell definition must not be null")
			continue
		var cell_errors := definition.validation_errors(grid)
		for error in cell_errors:
			errors.append("%s: %s" % [definition.id, error])
		if _definitions_by_coord.has(definition.coord):
			errors.append("duplicate cell coordinate: %s" % definition.coord)
		if ids.has(definition.id):
			errors.append("duplicate cell id: %s" % definition.id)
		_definitions_by_coord[definition.coord] = definition
		ids[definition.id] = true
	if not errors.is_empty():
		_definitions_by_coord.clear()
		return errors
	_grid = grid
	_backend = backend
	_config = config
	_configured = true
	return errors

func update_observer(position: Vector3, velocity: Vector3) -> void:
	if not _configured:
		return
	var residents: Dictionary = {}
	for coord in _loaded_by_coord.keys():
		residents[coord] = true
	var desired := _policy.desired_cells(_grid, _config, position, velocity, residents)
	var target: Dictionary = {}
	for key in ["visual", "predictive", "gameplay", "keep_resident"]:
		for coord in desired[key]:
			target[coord] = true
	var to_remove: Array = []
	for coord in _loaded_by_coord.keys():
		if not target.has(coord):
			to_remove.append(coord)
	for coord in to_remove:
		_unload_coord(coord)
	for coord in target.keys():
		if _loaded_by_coord.has(coord) or not _definitions_by_coord.has(coord):
			continue
		_load_coord(coord)

func loaded_cell_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for coord in _loaded_by_coord.keys():
		var definition: WorldCellDefinition = _definitions_by_coord[coord]
		ids.append(String(definition.id))
	ids.sort()
	return ids

func loaded_cell_count() -> int:
	return _loaded_by_coord.size()

func is_cell_loaded(coord: Vector2i) -> bool:
	return _loaded_by_coord.has(coord)

func _load_coord(coord: Vector2i) -> void:
	var definition: WorldCellDefinition = _definitions_by_coord[coord]
	var cell_node := _backend.create_cell(definition, _grid)
	if cell_node == null:
		return
	add_child(cell_node)
	_loaded_by_coord[coord] = cell_node
	cell_loaded.emit(definition.id, cell_node)

func _unload_coord(coord: Vector2i) -> void:
	if not _loaded_by_coord.has(coord):
		return
	var node: Node3D = _loaded_by_coord[coord]
	var definition: WorldCellDefinition = _definitions_by_coord[coord]
	_loaded_by_coord.erase(coord)
	if node.get_parent() == self:
		remove_child(node)
	_backend.release_cell(node)
	cell_unloaded.emit(definition.id)

func _clear_loaded() -> void:
	if _backend == null:
		for node in _loaded_by_coord.values():
			if is_instance_valid(node):
				if node.get_parent() == self:
					remove_child(node)
				node.free()
	else:
		for coord in _loaded_by_coord.keys().duplicate():
			_unload_coord(coord)
	_loaded_by_coord.clear()
