class_name VehicleEffectsBridge
extends Node

signal effects_state_changed(state: Dictionary)

@export var vehicle_path: NodePath = NodePath("..")
@export var visual_rig_path: NodePath = NodePath("../VisualRoot/VehicleVisualRig")
@export var brake_light_idle_energy := 0.30
@export var brake_light_full_energy := 5.0

var last_state: Dictionary = {}
var _visual_rig: Node
var _brake_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
    var rig = get_node_or_null(visual_rig_path)
    if rig != null:
        bind_visual_rig(rig)

func _process(_delta: float) -> void:
    var vehicle = get_node_or_null(vehicle_path)
    if vehicle == null or not vehicle.has_method("get_telemetry_snapshot"):
        return
    apply_snapshot(vehicle.get_telemetry_snapshot())

func bind_visual_rig(rig: Node) -> void:
    if _visual_rig != null and _visual_rig.has_signal("visual_rebuilt"):
        var old_callable := Callable(self, "_on_visual_rebuilt")
        if _visual_rig.is_connected("visual_rebuilt", old_callable):
            _visual_rig.disconnect("visual_rebuilt", old_callable)
    _visual_rig = rig
    if _visual_rig != null and _visual_rig.has_signal("visual_rebuilt"):
        var callback := Callable(self, "_on_visual_rebuilt")
        if not _visual_rig.is_connected("visual_rebuilt", callback):
            _visual_rig.connect("visual_rebuilt", callback)
    _bind_brake_materials()
    _apply_brake_light(float(last_state.get("brake_light", 0.0)))

func apply_snapshot(snapshot: Dictionary) -> void:
    last_state = build_state(snapshot)
    _apply_brake_light(float(last_state.get("brake_light", 0.0)))
    effects_state_changed.emit(last_state.duplicate(true))

static func build_state(snapshot: Dictionary) -> Dictionary:
    var wheels: Dictionary = snapshot.get("wheels", {})
    var peak_slip_energy := 0.0
    var dominant_surface := "air"
    var dominant_energy := -1.0
    var per_wheel := {}
    for id in ["fl", "fr", "rl", "rr"]:
        var wheel: Dictionary = wheels.get(id, {})
        var energy := maxf(0.0, float(wheel.get("slip_energy", 0.0)))
        var surface := String(wheel.get("surface", "air"))
        peak_slip_energy = maxf(peak_slip_energy, energy)
        if energy > dominant_energy and surface != "air":
            dominant_energy = energy
            dominant_surface = surface
        per_wheel[id] = {"slip_energy": energy, "surface": surface}
    var throttle := clampf(float(snapshot.get("throttle", 0.0)), 0.0, 1.0)
    var rpm := maxf(0.0, float(snapshot.get("engine_rpm", 0.0)))
    var impact := maxf(0.0, float(snapshot.get("body_contact_impulse", 0.0)))
    var damage: Dictionary = snapshot.get("damage", {})
    return {
        "brake_light": clampf(float(snapshot.get("brake", 0.0)), 0.0, 1.0),
        "reverse_active": int(snapshot.get("gear", 0)) < 0,
        "exhaust_intensity": clampf(throttle * (0.35 + rpm / 7000.0), 0.0, 1.0),
        "skid_intensity": clampf(peak_slip_energy / 900.0, 0.0, 1.0),
        "impact_intensity": clampf(impact / 5000.0, 0.0, 1.0),
        "damage_intensity": clampf(float(damage.get("severity", 0.0)), 0.0, 1.0),
        "dominant_surface": dominant_surface,
        "wheels": per_wheel,
    }

func _on_visual_rebuilt(_lod_index: int) -> void:
    _bind_brake_materials()
    _apply_brake_light(float(last_state.get("brake_light", 0.0)))

func _bind_brake_materials() -> void:
    _brake_materials.clear()
    if _visual_rig == null:
        return
    var stack: Array[Node] = [_visual_rig]
    while not stack.is_empty():
        var node: Node = stack.pop_back()
        if node is MeshInstance3D:
            var mesh_instance := node as MeshInstance3D
            if mesh_instance.mesh != null:
                for surface_index in range(mesh_instance.mesh.get_surface_count()):
                    var material := mesh_instance.get_active_material(surface_index)
                    if material is StandardMaterial3D and material.resource_name == "runtime_light_red":
                        var runtime_material := (material as StandardMaterial3D).duplicate() as StandardMaterial3D
                        runtime_material.resource_name = "runtime_light_red"
                        runtime_material.emission_enabled = true
                        mesh_instance.set_surface_override_material(surface_index, runtime_material)
                        _brake_materials.append(runtime_material)
        for child in node.get_children():
            stack.append(child)

func _apply_brake_light(brake: float) -> void:
    var demand := clampf(brake, 0.0, 1.0)
    var energy := lerpf(brake_light_idle_energy, brake_light_full_energy, pow(demand, 1.25))
    for material in _brake_materials:
        material.emission_energy_multiplier = energy
