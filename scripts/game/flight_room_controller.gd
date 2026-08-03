class_name FlightRoomController
extends Node3D

signal route_progress_changed(passed_gates: int, total_gates: int)
signal state_changed(state: int)

const STATE_FLYING: int = 0
const STATE_CRASHED: int = 1
const STATE_COMPLETED: int = 2

@export var craft_path: NodePath = NodePath("FrontierVTOL")
@export var input_adapter_path: NodePath = NodePath("PilotInputAdapter")
@export var camera_rig_path: NodePath = NodePath("FlightCameraRig")
@export var landing_zone_path: NodePath = NodePath("LandingZone")
@export var hud_path: NodePath = NodePath("FlightHud")

var _state: int = STATE_FLYING
var _total_gates: int = 0
var _next_gate_index: int = 0
var _landing_zone_occupied: bool = false
var _spawn_transform := Transform3D.IDENTITY
var _spawn_captured: bool = false
var _craft: FrontierVtolController
var _input_adapter: PilotInputAdapter
var _camera_rig: FlightCameraRig
var _landing_zone: Area3D
var _hud: FlightHud
var _gates: Array[RouteGate] = []


func _ready() -> void:
	_resolve_runtime_nodes()
	_collect_route_gates()
	configure_gate_count(_gates.size())
	_connect_runtime_signals()
	if _craft != null:
		_spawn_transform = _craft.transform
		_spawn_captured = true
	_refresh_gate_states()
	_sync_hud()


func configure_gate_count(gate_count: int) -> void:
	_total_gates = maxi(gate_count, 0)
	_next_gate_index = 0
	_landing_zone_occupied = false
	_set_state(STATE_FLYING)
	route_progress_changed.emit(_next_gate_index, _total_gates)


func try_pass_gate(gate_index: int) -> bool:
	if _state != STATE_FLYING:
		return false
	if gate_index != _next_gate_index or _next_gate_index >= _total_gates:
		return false

	if _next_gate_index < _gates.size():
		_gates[_next_gate_index].mark_completed()
	_next_gate_index += 1
	_refresh_gate_states()
	route_progress_changed.emit(_next_gate_index, _total_gates)
	return true


func handle_landing() -> bool:
	if _state != STATE_FLYING:
		return false
	if not _landing_zone_occupied:
		return false
	if _next_gate_index != _total_gates:
		return false
	_set_state(STATE_COMPLETED)
	return true


func handle_crash() -> void:
	if _state == STATE_COMPLETED:
		return
	_set_state(STATE_CRASHED)


func restart_run() -> void:
	_next_gate_index = 0
	_landing_zone_occupied = false
	for gate in _gates:
		gate.reset_gate()
	_refresh_gate_states()
	if _craft != null and _spawn_captured:
		_craft.reset_to(_spawn_transform)
	if _input_adapter != null:
		_input_adapter.reset_controls()
	if _camera_rig != null:
		_camera_rig.set_mode(FlightCameraRig.MODE_CHASE)
	_set_state(STATE_FLYING)
	route_progress_changed.emit(_next_gate_index, _total_gates)


func set_landing_zone_occupied(value: bool) -> void:
	_landing_zone_occupied = value


func is_landing_zone_occupied() -> bool:
	return _landing_zone_occupied


func get_state() -> int:
	return _state


func get_next_gate_index() -> int:
	return _next_gate_index


func get_route_progress() -> Vector2i:
	return Vector2i(_next_gate_index, _total_gates)


func _resolve_runtime_nodes() -> void:
	_craft = get_node_or_null(craft_path) as FrontierVtolController
	_input_adapter = get_node_or_null(input_adapter_path) as PilotInputAdapter
	_camera_rig = get_node_or_null(camera_rig_path) as FlightCameraRig
	_landing_zone = get_node_or_null(landing_zone_path) as Area3D
	_hud = get_node_or_null(hud_path) as FlightHud


func _collect_route_gates() -> void:
	_gates.clear()
	for candidate in get_tree().get_nodes_in_group("route_gate"):
		if candidate is RouteGate and is_ancestor_of(candidate):
			_gates.append(candidate)
	_gates.sort_custom(_gate_index_before)


func _connect_runtime_signals() -> void:
	if _input_adapter != null and _craft != null:
		_connect_once(_input_adapter.command_updated, _craft.set_pilot_command)
	if _input_adapter != null and _camera_rig != null:
		_connect_once(_input_adapter.camera_toggle_requested, _camera_rig.toggle_mode)
	if _input_adapter != null:
		_connect_once(_input_adapter.restart_requested, restart_run)
	if _craft != null:
		_connect_once(_craft.crashed, handle_crash)
		_connect_once(_craft.landed, handle_landing)
	if _landing_zone != null:
		_connect_once(_landing_zone.body_entered, _on_landing_body_entered)
		_connect_once(_landing_zone.body_exited, _on_landing_body_exited)
	for gate in _gates:
		_connect_once(gate.vehicle_passed, try_pass_gate)
	if _hud != null:
		_connect_once(route_progress_changed, _hud.set_route_progress)
		_connect_once(state_changed, _hud.set_state)
		if _craft != null:
			_connect_once(_craft.telemetry_updated, _hud.update_telemetry)


func _refresh_gate_states() -> void:
	for gate in _gates:
		gate.set_active(
			_state == STATE_FLYING
			and gate.gate_index == _next_gate_index
		)


func _set_state(value: int) -> void:
	if _state == value:
		return
	_state = value
	_refresh_gate_states()
	state_changed.emit(_state)


func _sync_hud() -> void:
	if _hud == null:
		return
	_hud.set_route_progress(_next_gate_index, _total_gates)
	_hud.set_state(_state)
	if _craft != null:
		_hud.update_telemetry(_craft.get_telemetry())


func _gate_index_before(left: RouteGate, right: RouteGate) -> bool:
	return left.gate_index < right.gate_index


func _connect_once(signal_value: Signal, callable_value: Callable) -> void:
	if not signal_value.is_connected(callable_value):
		signal_value.connect(callable_value)


func _on_landing_body_entered(body: Node3D) -> void:
	if body == _craft:
		_landing_zone_occupied = true


func _on_landing_body_exited(body: Node3D) -> void:
	if body == _craft:
		_landing_zone_occupied = false