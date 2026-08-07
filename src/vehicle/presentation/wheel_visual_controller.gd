class_name WheelVisualController
extends Node

@export var vehicle_path: NodePath = NodePath("..")
@export var visual_rig_path: NodePath = NodePath("../VisualRoot/VehicleVisualRig")
@export var steering_wheel_ratio := 9.0

var _visual_rig: Node
var _wheel_rest: Dictionary = {}
var _wheel_spin: Dictionary = {"fl": 0.0, "fr": 0.0, "rl": 0.0, "rr": 0.0}
var _compression_reference: Dictionary = {}
var _steering_rest := Transform3D.IDENTITY
var _steering_bound := false

func _ready() -> void:
    _resolve_visual_rig()

func _physics_process(delta: float) -> void:
    var vehicle := get_node_or_null(vehicle_path)
    if vehicle == null or not vehicle.has_method("get_telemetry_snapshot"):
        return
    var data: Dictionary = vehicle.call("get_telemetry_snapshot")
    if _visual_rig == null:
        _resolve_visual_rig()
    if _visual_rig == null or not _visual_rig.call("is_runtime_visual_loaded"):
        _animate_fallback(data, delta)
        return
    if _wheel_rest.size() != 4:
        _bind_runtime_nodes()
    var wheels: Dictionary = data.get("wheels", {})
    var steer_angle := float(data.get("steering_angle_rad", 0.0))
    for id in ["fl", "fr", "rl", "rr"]:
        var node := _visual_rig.call("get_physical_wheel_node", id) as Node3D
        if node == null or not _wheel_rest.has(id):
            continue
        var wheel_data: Dictionary = wheels.get(id, {})
        var compression := float(wheel_data.get("compression", 0.0))
        var grounded := bool(wheel_data.get("grounded", true))
        if grounded and not _compression_reference.has(id):
            _compression_reference[id] = compression
        var reference := float(_compression_reference.get(id, compression))
        var suspension_delta := compression - reference
        var rpm := float(wheel_data.get("rpm", 0.0))
        _wheel_spin[id] = fposmod(float(_wheel_spin[id]) + rpm * TAU / 60.0 * delta, TAU)
        var rest: Transform3D = _wheel_rest[id]
        node.position = rest.origin + Vector3.UP * suspension_delta
        var steering := steer_angle if id in ["fl", "fr"] else 0.0
        node.basis = Basis(Vector3.UP, steering) * Basis(Vector3.RIGHT, float(_wheel_spin[id])) * rest.basis
    var steering_wheel := _visual_rig.call("get_steering_wheel_node") as Node3D
    if steering_wheel != null and _steering_bound:
        steering_wheel.basis = Basis(Vector3.FORWARD, -steer_angle * steering_wheel_ratio) * _steering_rest.basis

func _animate_fallback(data: Dictionary, delta: float) -> void:
    var wheels: Dictionary = data.get("wheels", {})
    var steer_angle := float(data.get("steering_angle_rad", 0.0))
    for id in ["fl", "fr", "rl", "rr"]:
        var node := get_node_or_null("../VisualRoot/GreyboxFallback/WheelVisual%s" % id.to_upper()) as Node3D
        if node == null:
            continue
        var wheel_data: Dictionary = wheels.get(id, {})
        var rpm := float(wheel_data.get("rpm", 0.0))
        _wheel_spin[id] = fposmod(float(_wheel_spin[id]) + rpm * TAU / 60.0 * delta, TAU)
        var steering := steer_angle if id in ["fl", "fr"] else 0.0
        node.basis = Basis(Vector3.UP, steering) * Basis(Vector3.RIGHT, float(_wheel_spin[id]))
    var steering_wheel := get_node_or_null("../VisualRoot/GreyboxFallback/BodyInterior/SteeringWheelPivot") as Node3D
    if steering_wheel != null:
        steering_wheel.rotation.z = -steer_angle * steering_wheel_ratio

func _resolve_visual_rig() -> void:
    _visual_rig = get_node_or_null(visual_rig_path)
    if _visual_rig == null:
        return
    if _visual_rig.has_signal("visual_rebuilt") and not _visual_rig.is_connected("visual_rebuilt", _on_visual_rebuilt):
        _visual_rig.connect("visual_rebuilt", _on_visual_rebuilt)
    _bind_runtime_nodes()

func _bind_runtime_nodes() -> void:
    _wheel_rest.clear()
    _compression_reference.clear()
    _steering_bound = false
    if _visual_rig == null or not _visual_rig.call("is_runtime_visual_loaded"):
        return
    for id in ["fl", "fr", "rl", "rr"]:
        var node := _visual_rig.call("get_physical_wheel_node", id) as Node3D
        if node != null:
            _wheel_rest[id] = node.transform
            _wheel_spin[id] = 0.0
    var steering_wheel := _visual_rig.call("get_steering_wheel_node") as Node3D
    if steering_wheel != null:
        _steering_rest = steering_wheel.transform
        _steering_bound = true

func _on_visual_rebuilt(_lod_index: int) -> void:
    _bind_runtime_nodes()
