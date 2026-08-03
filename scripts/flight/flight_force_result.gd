class_name FlightForceResult
extends RefCounted

var force_world: Vector3 = Vector3.ZERO
var torque_world: Vector3 = Vector3.ZERO
var thrust_force_world: Vector3 = Vector3.ZERO
var drag_force_world: Vector3 = Vector3.ZERO
var lift_force_world: Vector3 = Vector3.ZERO
var gravity_force_world: Vector3 = Vector3.ZERO
var thrust_newtons: float = 0.0
var drag_newtons: float = 0.0
var lift_newtons: float = 0.0