class_name EngineConfig
extends Resource
@export var idle_rpm:=850.0
@export var redline_rpm:=7200.0
@export var limiter_rpm:=7400.0
@export var inertia:=0.22
@export var engine_brake_torque:=42.0
@export var torque_curve:PackedVector2Array=PackedVector2Array([Vector2(850,130),Vector2(2000,165),Vector2(3500,195),Vector2(4800,200),Vector2(6000,190),Vector2(7000,165)])
