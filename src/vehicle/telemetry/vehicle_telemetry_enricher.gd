class_name VehicleTelemetryEnricher
extends Node

signal telemetry_enriched(snapshot: Dictionary)

@export var vehicle_path: NodePath = NodePath("..")

var _previous_compression := {"fl": 0.0, "fr": 0.0, "rl": 0.0, "rr": 0.0}
var _has_previous := {"fl": false, "fr": false, "rl": false, "rr": false}
var _frame_delta_s := 0.0
var _last_snapshot: Dictionary = {}

func _process(delta: float) -> void:
    _frame_delta_s = maxf(delta, 0.0)

func _physics_process(delta: float) -> void:
    var vehicle = get_node_or_null(vehicle_path)
    if vehicle == null or not vehicle.has_method("get_telemetry_snapshot"):
        return
    _last_snapshot = enrich_snapshot(vehicle.get_telemetry_snapshot(), delta, _frame_delta_s)
    telemetry_enriched.emit(_last_snapshot.duplicate(true))

func get_enriched_snapshot() -> Dictionary:
    return _last_snapshot.duplicate(true)

func enrich_snapshot(snapshot: Dictionary, physics_delta_s: float, frame_delta_s: float = 0.0) -> Dictionary:
    var started_usec := Time.get_ticks_usec()
    var enriched := snapshot.duplicate(true)
    var wheels: Dictionary = enriched.get("wheels", {})
    var dt := maxf(physics_delta_s, 0.000001)
    for id in ["fl", "fr", "rl", "rr"]:
        var wheel: Dictionary = wheels.get(id, {}).duplicate(true)
        var compression := float(wheel.get("compression", 0.0))
        var suspension_velocity := 0.0
        if bool(_has_previous.get(id, false)):
            suspension_velocity = (compression - float(_previous_compression.get(id, compression))) / dt
        _previous_compression[id] = compression
        _has_previous[id] = true
        wheel["suspension_velocity_mps"] = suspension_velocity
        wheel["wetness"] = _surface_wetness(wheel)
        wheels[id] = wheel
    enriched["wheels"] = wheels
    enriched["timing"] = {
        "physics_delta_s": physics_delta_s,
        "physics_hz": 1.0 / dt,
        "frame_delta_s": frame_delta_s,
        "frame_fps": 1.0 / frame_delta_s if frame_delta_s > 0.000001 else 0.0,
        "enrichment_usec": max(0, Time.get_ticks_usec() - started_usec),
    }
    return enriched

static func _surface_wetness(wheel: Dictionary) -> float:
    if wheel.has("wetness"):
        return clampf(float(wheel.get("wetness", 0.0)), 0.0, 1.0)
    return 1.0 if StringName(wheel.get("surface", &"air")) == &"asphalt_wet" else 0.0
