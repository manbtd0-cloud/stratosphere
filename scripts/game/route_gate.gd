class_name RouteGate
extends Area3D

signal vehicle_passed(gate_index: int)

@export var gate_index: int = 0

var _completed: bool = false
var _active: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_refresh_monitoring()


func set_active(value: bool) -> void:
	_active = value and not _completed
	_refresh_monitoring()


func mark_completed() -> void:
	_completed = true
	_active = false
	_refresh_monitoring()
	var visual_root := get_node_or_null("VisualRoot") as Node3D
	if visual_root != null:
		visual_root.visible = false


func reset_gate() -> void:
	_completed = false
	_active = false
	_refresh_monitoring()
	var visual_root := get_node_or_null("VisualRoot") as Node3D
	if visual_root != null:
		visual_root.visible = true


func is_completed() -> bool:
	return _completed


func is_active() -> bool:
	return _active


func _refresh_monitoring() -> void:
	monitoring = _active and not _completed
	monitorable = true


func _on_body_entered(body: Node3D) -> void:
	if not _active or _completed:
		return
	if body is FrontierVtolController:
		vehicle_passed.emit(gate_index)