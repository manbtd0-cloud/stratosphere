class_name FlightCameraRig
extends Node3D

const MODE_COCKPIT: int = 0
const MODE_CHASE: int = 1

@export var craft_path: NodePath
@export var control_profile: FlightControlProfile
@export var cockpit_fov_degrees: float = 84.0

var _mode: int = MODE_CHASE
var _craft: Node3D
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

	var profile := _profile()
	var safe_delta := maxf(delta, 0.0) if is_finite(delta) else 0.0
	var target := _chase_target_transform()
	var target_fov := calculate_chase_fov(_craft_speed_mps())
	if not _initialized_transform:
		global_transform = target
		_set_camera_fov(target_fov)
		_initialized_transform = true
		return

	var position_weight := _follow_weight(profile.chase_position_response, safe_delta)
	var rotation_weight := _follow_weight(profile.chase_rotation_response, safe_delta)
	var blended_origin := global_transform.origin.lerp(target.origin, position_weight)
	var current_rotation := Quaternion(global_transform.basis.orthonormalized())
	var target_rotation := Quaternion(target.basis.orthonormalized())
	var blended_basis := Basis(current_rotation.slerp(target_rotation, rotation_weight))
	global_transform = Transform3D(blended_basis, blended_origin)

	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera != null:
		var fov_weight := _follow_weight(profile.chase_fov_response, safe_delta)
		camera.fov = lerpf(camera.fov, target_fov, fov_weight)


func bind_to_craft(craft: Node) -> bool:
	if craft == null or not (craft is Node3D):
		_clear_binding()
		return false

	var cockpit := craft.get_node_or_null("CockpitAnchor") as Node3D
	var chase := craft.get_node_or_null("ChaseAnchor") as Node3D
	if cockpit == null or chase == null:
		_clear_binding()
		return false

	_craft = craft as Node3D
	_cockpit_anchor = cockpit
	_chase_anchor = chase
	_initialized_transform = false
	return true


func is_bound() -> bool:
	return (
		is_instance_valid(_craft)
		and is_instance_valid(_cockpit_anchor)
		and is_instance_valid(_chase_anchor)
	)


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
	if _mode == MODE_COCKPIT:
		global_transform = _cockpit_anchor.global_transform
		_set_camera_fov(cockpit_fov_degrees)
	else:
		global_transform = _chase_target_transform()
		_set_camera_fov(calculate_chase_fov(_craft_speed_mps()))
	_initialized_transform = true


func calculate_chase_fov(speed_mps: float) -> float:
	var profile := _profile()
	var speed := maxf(speed_mps, 0.0) if is_finite(speed_mps) else 0.0
	var minimum := clampf(_finite_or(profile.min_chase_fov_degrees, 76.0), 50.0, 120.0)
	var maximum := clampf(
		_finite_or(profile.max_chase_fov_degrees, 92.0),
		minimum,
		120.0
	)
	var full_speed := maxf(_finite_or(profile.chase_fov_full_speed_mps, 210.0), 1.0)
	var weight := clampf(speed / full_speed, 0.0, 1.0)
	return lerpf(minimum, maximum, weight)


func calculate_velocity_lookahead(velocity_world: Vector3) -> Vector3:
	var profile := _profile()
	var safe_velocity := Vector3(
		velocity_world.x if is_finite(velocity_world.x) else 0.0,
		velocity_world.y if is_finite(velocity_world.y) else 0.0,
		velocity_world.z if is_finite(velocity_world.z) else 0.0
	)
	var seconds := clampf(_finite_or(profile.chase_lookahead_seconds, 0.28), 0.0, 2.0)
	var maximum := clampf(
		_finite_or(profile.chase_max_lookahead_meters, 28.0),
		0.0,
		80.0
	)
	return (safe_velocity * seconds).limit_length(maximum)


func attenuate_chase_roll(target_basis: Basis) -> Basis:
	var target := target_basis.orthonormalized()
	var forward := -target.z.normalized()
	if forward.length_squared() < 0.999:
		return target
	if absf(forward.dot(Vector3.UP)) > 0.98:
		return target

	var stable_right := forward.cross(Vector3.UP).normalized()
	var stable_up := stable_right.cross(forward).normalized()
	var stable_basis := Basis(stable_right, stable_up, -forward).orthonormalized()
	var amount := clampf(
		_finite_or(_profile().chase_roll_follow_amount, 0.38),
		0.0,
		1.0
	)
	return Basis(
		Quaternion(stable_basis).slerp(Quaternion(target), amount)
	).orthonormalized()


func _chase_target_transform() -> Transform3D:
	var anchor_transform := _chase_anchor.global_transform
	var attenuated_basis := attenuate_chase_roll(anchor_transform.basis)
	var target := Transform3D(attenuated_basis, anchor_transform.origin)
	if not is_instance_valid(_craft):
		return target

	var focus_point := (
		_craft.global_transform.origin
		+ calculate_velocity_lookahead(_craft_velocity_world())
	)
	if target.origin.distance_squared_to(focus_point) <= 0.000001:
		return target
	var up := attenuated_basis.y.normalized()
	var view_direction := (focus_point - target.origin).normalized()
	if absf(view_direction.dot(up)) > 0.98:
		up = Vector3.UP
	return target.looking_at(focus_point, up)


func _craft_velocity_world() -> Vector3:
	if _craft is RigidBody3D:
		return (_craft as RigidBody3D).linear_velocity
	return Vector3.ZERO


func _craft_speed_mps() -> float:
	return _craft_velocity_world().length()


func _follow_weight(response: float, delta: float) -> float:
	var safe_response := clampf(_finite_or(response, 0.0), 0.0, 40.0)
	return 1.0 - exp(-safe_response * delta)


func _set_camera_fov(value: float) -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera != null:
		camera.fov = value


func _profile() -> FlightControlProfile:
	if control_profile == null:
		control_profile = FlightControlProfile.new()
	return control_profile


func _clear_binding() -> void:
	_craft = null
	_cockpit_anchor = null
	_chase_anchor = null
	_initialized_transform = false


func _finite_or(value: float, fallback: float) -> float:
	return value if is_finite(value) else fallback
