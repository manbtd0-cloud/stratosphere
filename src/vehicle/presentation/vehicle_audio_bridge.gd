class_name VehicleAudioBridge
extends Node

signal audio_state_changed(state: Dictionary)
signal gear_changed(gear: int)

@export var vehicle_path: NodePath = NodePath("..")

var last_state: Dictionary = {}
var _last_gear := 0

func _process(_delta: float) -> void:
    var vehicle = get_node_or_null(vehicle_path)
    if vehicle == null or not vehicle.has_method("get_telemetry_snapshot"):
        return
    var idle_rpm := 850.0
    var limiter_rpm := 6800.0
    var definition = vehicle.get("definition")
    if definition != null and definition.get("engine") != null:
        idle_rpm = float(definition.engine.idle_rpm)
        limiter_rpm = float(definition.engine.limiter_rpm)
    apply_snapshot(vehicle.get_telemetry_snapshot(), idle_rpm, limiter_rpm)

func apply_snapshot(snapshot: Dictionary, idle_rpm: float = 850.0, limiter_rpm: float = 6800.0) -> void:
    last_state = build_state(snapshot, idle_rpm, limiter_rpm)
    var gear := int(last_state.get("gear", 0))
    if gear != _last_gear:
        _last_gear = gear
        gear_changed.emit(gear)
    audio_state_changed.emit(last_state.duplicate(true))

static func build_state(snapshot: Dictionary, idle_rpm: float = 850.0, limiter_rpm: float = 6800.0) -> Dictionary:
    var rpm := maxf(0.0, float(snapshot.get("engine_rpm", 0.0)))
    var rpm_range := maxf(1.0, limiter_rpm - idle_rpm)
    var rpm_normalized := clampf((rpm - idle_rpm) / rpm_range, 0.0, 1.0)
    var pitch_ratio := lerpf(0.68, 2.05, rpm_normalized)
    var wheels: Dictionary = snapshot.get("wheels", {})
    var peak_slip_energy := 0.0
    var surface_counts: Dictionary = {}
    for id in ["fl", "fr", "rl", "rr"]:
        var wheel: Dictionary = wheels.get(id, {})
        peak_slip_energy = maxf(peak_slip_energy, float(wheel.get("slip_energy", 0.0)))
        var surface := String(wheel.get("surface", "air"))
        if surface != "air" and not surface.is_empty():
            surface_counts[surface] = int(surface_counts.get(surface, 0)) + 1
    var dominant_surface := "air"
    var dominant_count := -1
    for surface in surface_counts:
        var count := int(surface_counts[surface])
        if count > dominant_count:
            dominant_count = count
            dominant_surface = String(surface)
    return {
        "engine_rpm": rpm,
        "engine_rpm_normalized": rpm_normalized,
        "engine_pitch_ratio": pitch_ratio,
        "engine_load": clampf(float(snapshot.get("throttle", 0.0)), 0.0, 1.0),
        "engine_torque": float(snapshot.get("engine_torque", 0.0)),
        "speed_mps": float(snapshot.get("speed_mps", 0.0)),
        "gear": int(snapshot.get("gear", 0)),
        "tire_slip_energy": peak_slip_energy,
        "dominant_surface": dominant_surface,
        "impact_impulse": maxf(0.0, float(snapshot.get("body_contact_impulse", 0.0))),
    }
