class_name VehicleRecoveryCoordinator
extends Node

signal recovery_transform_updated(transform: Transform3D)
signal auto_recovered

@export var vehicle_path: NodePath = NodePath("..")
@export var safe_update_interval := 0.35
@export var auto_recovery_delay := 2.5
@export var minimum_grounded_wheels := 3
@export var maximum_safe_record_speed := 45.0
@export var maximum_auto_recovery_speed := 1.5
@export var safe_up_dot := 0.65
@export var inverted_up_dot := 0.25
@export var auto_recovery_enabled := true

var _vehicle: RigidBody3D
var _last_valid_transform := Transform3D.IDENTITY
var _has_valid_transform := false
var _safe_elapsed := 0.0
var _inverted_elapsed := 0.0

func _ready() -> void:
    _vehicle = get_node_or_null(vehicle_path) as RigidBody3D
    if _vehicle != null:
        _last_valid_transform = _vehicle.global_transform
        _has_valid_transform = true
        _publish_recovery_transform()

func _physics_process(delta: float) -> void:
    if _vehicle == null:
        return
    var snapshot: Dictionary = _vehicle.get_telemetry_snapshot() if _vehicle.has_method("get_telemetry_snapshot") else {}
    var grounded := _grounded_wheel_count(snapshot)
    var up_dot := _vehicle.global_basis.y.normalized().dot(Vector3.UP)
    var speed := _vehicle.linear_velocity.length()
    if should_record_safe_transform(up_dot, grounded, speed, maximum_safe_record_speed, minimum_grounded_wheels, safe_up_dot):
        _safe_elapsed += delta
        if _safe_elapsed >= safe_update_interval:
            _safe_elapsed = 0.0
            _last_valid_transform = _vehicle.global_transform
            _has_valid_transform = true
            _publish_recovery_transform()
    else:
        _safe_elapsed = 0.0
    if auto_recovery_enabled and up_dot <= inverted_up_dot and speed <= maximum_auto_recovery_speed:
        _inverted_elapsed += delta
    else:
        _inverted_elapsed = 0.0
    if auto_recovery_enabled and should_auto_recover(up_dot, speed, _inverted_elapsed, auto_recovery_delay, inverted_up_dot, maximum_auto_recovery_speed):
        recover_now()
        _inverted_elapsed = 0.0
        auto_recovered.emit()

func recover_now() -> void:
    if _vehicle == null:
        return
    if _has_valid_transform:
        _publish_recovery_transform()
    if _vehicle.has_method("reset_vehicle"):
        _vehicle.call("reset_vehicle")
    else:
        _vehicle.global_transform = _last_valid_transform if _has_valid_transform else _vehicle.global_transform
        _vehicle.linear_velocity = Vector3.ZERO
        _vehicle.angular_velocity = Vector3.ZERO
        _vehicle.reset_physics_interpolation()

func get_last_valid_transform() -> Transform3D:
    return _last_valid_transform

static func should_record_safe_transform(up_dot: float, grounded_wheels: int, speed_mps: float, max_speed: float = 45.0, minimum_grounded: int = 3, minimum_up_dot: float = 0.65) -> bool:
    return is_finite(up_dot) and is_finite(speed_mps) and up_dot >= minimum_up_dot and grounded_wheels >= minimum_grounded and speed_mps <= max_speed

static func should_auto_recover(up_dot: float, speed_mps: float, inverted_duration: float, delay: float, maximum_inverted_up_dot: float = 0.25, maximum_speed: float = 1.5) -> bool:
    return is_finite(up_dot) and is_finite(speed_mps) and is_finite(inverted_duration) and up_dot <= maximum_inverted_up_dot and speed_mps <= maximum_speed and inverted_duration >= delay

static func _grounded_wheel_count(snapshot: Dictionary) -> int:
    var count := 0
    var wheels: Dictionary = snapshot.get("wheels", {})
    for id in ["fl", "fr", "rl", "rr"]:
        if bool((wheels.get(id, {}) as Dictionary).get("grounded", false)):
            count += 1
    return count

func _publish_recovery_transform() -> void:
    if _vehicle == null or not _has_valid_transform:
        return
    for property in _vehicle.get_property_list():
        if String(property.get("name", "")) == "spawn_transform":
            _vehicle.set("spawn_transform", _last_valid_transform)
            break
    recovery_transform_updated.emit(_last_valid_transform)
