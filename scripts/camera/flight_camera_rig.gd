class_name FlightCameraRig
extends Node3D

const MODE_COCKPIT: int = 0
const MODE_CHASE: int = 1

@export var craft_path: NodePath
@export var chase_follow_response: float = 9.0
@export var cockpit_fov_degrees: float = 84.0
@export var chase_fov_degrees: float = 78.0

var _mode: int = MODE_CHASE
var _cockpit_anchor: Node3D
var _chase_anchor: Node3D
var _initialized_transform: bool = false


func _ready() -> void:
	if not craft_path.is_empty():
		bind_to_craft(get_node_or_null(craft_path))
	if is_bound():
		snap_to_active_anchor()


func _process(delta: float) -> void:
	if not is_bound():
		return

	if _mode == MODE_COCKPIT:
		global_transform = _cockpit_anchor.global_transform
		_set_camera_fov(cockpit_fov_degrees)
		_initialized_transform = true
		return

	var target := _chase_anchor.global_transform
	if not _initialized_transform:
		global_transform = target
		_initialized_transform = true
	else:
		var weight := 1.0 - exp(-maxf(chase_follow_response, 0.0) * maxf(delta, 0.0))
		var blended_origin := global_transform.origin.lerp(target.origin, weight)
		var current_rotation := Quaternion(global_transform.basis.orthonormalized())
		var target_rotation := Quaternion(target.basis.orthonormalized())
		var blended_basis := Basis(current_rotation.slerp(target_rotation, weight))
		global_transform = Transform3D(blended_basis, blended_origin)
	_set_camera_fov(chase_fov_degrees)


func bind_to_craft(craft: Node) -> bool:
	if craft == null:
		_clear_binding()
		return false

	var cockpit := craft.get_node_or_null("CockpitAnchor") as Node3D
	var chase := craft.get_node_or_null("ChaseAnchor") as Node3D
	if cockpit == null or chase == null:
		_clear_binding()
		return false

	_cockpit_anchor = cockpit
	_chase_anchor = chase
	_initialized_transform = false
	return true


func is_bound() -> bool:
	return is_instance_valid(_cockpit_anchor) and is_instance_valid(_chase_anchor)


func set_mode(requested_mode: int) -> bool:
	if requested_mode != MODE_COCKPIT and requested_mode != MODE_CHASE:
		return false
	_mode = requested_mode
	_initialized_transform = false
	if is_inside_tree() and is_bound():
		snap_to_active_anchor()
	return true


func toggle_mode() -> int:
	if _mode == MODE_CHASE:
		set_mode(MODE_COCKPIT)
	else:
		set_mode(MODE_CHASE)
	return _mode


func get_mode() -> int:
	return _mode


func snap_to_active_anchor() -> void:
	if not is_bound():
		return
	var anchor := _cockpit_anchor if _mode == MODE_COCKPIT else _chase_anchor
	global_transform = anchor.global_transform
	_initialized_transform = true
	_set_camera_fov(
		cockpit_fov_degrees if _mode == MODE_COCKPIT else chase_fov_degrees
	)


func _set_camera_fov(value: float) -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera != null:
		camera.fov = value


func _clear_binding() -> void:
	_cockpit_anchor = null
	_chase_anchor = null
	_initialized_transform = false