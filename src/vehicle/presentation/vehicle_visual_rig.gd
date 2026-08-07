class_name VehicleVisualRig
extends Node3D

signal visual_rebuilt(lod_index: int)

const PHYSICAL_WHEEL_SEMANTICS := {
    "fl": "wheel_fr_visual",
    "fr": "wheel_fl_visual",
    "rl": "wheel_rr_visual",
    "rr": "wheel_rl_visual",
}

@export var runtime_root := "res://assets/runtime/vehicle/prototype_rwd_coupe"
@export_range(0, 3, 1) var initial_lod := 0
@export var model_yaw_degrees := 180.0
@export var model_vertical_offset := -0.39
@export var fallback_path: NodePath

var _active_lod := -1
var _model_root: Node3D
var _semantic_nodes: Dictionary = {}

func _ready() -> void:
    set_lod(initial_lod)

func runtime_path(lod_index: int) -> String:
    return "%s/prototype_rwd_coupe_lod%d.glb" % [runtime_root.trim_suffix("/"), clampi(lod_index, 0, 3)]

func is_runtime_visual_loaded() -> bool:
    return _model_root != null

func get_active_lod() -> int:
    return _active_lod

func get_semantic_node(name: StringName) -> Node3D:
    return _semantic_nodes.get(String(name)) as Node3D

func get_physical_wheel_node(id: String) -> Node3D:
    return get_semantic_node(StringName(PHYSICAL_WHEEL_SEMANTICS.get(id, "")))

func get_steering_wheel_node() -> Node3D:
    return get_semantic_node(&"steering_wheel_visual")

func set_lod(lod_index: int) -> bool:
    lod_index = clampi(lod_index, 0, 3)
    if _active_lod == lod_index and _model_root != null:
        return true
    var path := runtime_path(lod_index)
    if not FileAccess.file_exists(path):
        _set_fallback_visible(true)
        return false
    var resource := load(path)
    if resource == null or not resource is PackedScene:
        _set_fallback_visible(true)
        return false
    var next_root := (resource as PackedScene).instantiate() as Node3D
    if next_root == null:
        _set_fallback_visible(true)
        return false
    next_root.name = "RuntimeLOD%d" % lod_index
    next_root.rotation.y = deg_to_rad(model_yaw_degrees)
    next_root.position.y = model_vertical_offset
    if _model_root != null:
        remove_child(_model_root)
        _model_root.queue_free()
    add_child(next_root)
    _model_root = next_root
    _active_lod = lod_index
    _index_semantics()
    _set_fallback_visible(false)
    visual_rebuilt.emit(_active_lod)
    return true

func _index_semantics() -> void:
    _semantic_nodes.clear()
    if _model_root == null:
        return
    var stack: Array[Node] = [_model_root]
    while not stack.is_empty():
        var node: Node = stack.pop_back()
        if node is Node3D:
            _semantic_nodes[String(node.name)] = node
        for child in node.get_children():
            stack.append(child)

func _set_fallback_visible(value: bool) -> void:
    if fallback_path.is_empty():
        return
    var fallback := get_node_or_null(fallback_path) as Node3D
    if fallback != null:
        fallback.visible = value
