class_name NavigationGraph
extends RefCounted

var _nodes: Dictionary = {}
var _edges: Dictionary = {}
var _outgoing: Dictionary = {}

func add_node(node_id: StringName, position: Vector3) -> Error:
	if node_id.is_empty() or not position.is_finite(): return ERR_INVALID_PARAMETER
	if _nodes.has(node_id): return ERR_ALREADY_EXISTS
	_nodes[node_id] = position
	_outgoing[node_id] = []
	return OK

func add_edge(edge: NavigationEdge) -> Error:
	if edge == null or not edge.validation_errors().is_empty(): return ERR_INVALID_DATA
	if _edges.has(edge.id): return ERR_ALREADY_EXISTS
	if not _nodes.has(edge.from_node_id) or not _nodes.has(edge.to_node_id): return ERR_DOES_NOT_EXIST
	_edges[edge.id] = edge
	_outgoing[edge.from_node_id].append(edge.id)
	_outgoing[edge.from_node_id].sort_custom(func(a, b): return String(a) < String(b))
	return OK

func node_count() -> int:
	return _nodes.size()

func node_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for node_id in _nodes.keys(): result.append(node_id)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result

func edge_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for edge_id in _edges.keys(): result.append(edge_id)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result

func get_node_position(node_id: StringName) -> Vector3:
	return _nodes.get(node_id, Vector3(INF, INF, INF))

func get_edge(edge_id: StringName) -> NavigationEdge:
	return _edges.get(edge_id) as NavigationEdge

func outgoing_edges(node_id: StringName) -> Array[NavigationEdge]:
	var result: Array[NavigationEdge] = []
	for edge_id in _outgoing.get(node_id, []):
		var edge := get_edge(edge_id)
		if edge != null: result.append(edge)
	return result

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	for edge_id in edge_ids():
		var edge := get_edge(edge_id)
		for error in edge.validation_errors(): errors.append("%s: %s" % [edge_id, error])
		if not _nodes.has(edge.from_node_id) or not _nodes.has(edge.to_node_id):
			errors.append("%s references missing navigation node" % edge_id)
	return errors
