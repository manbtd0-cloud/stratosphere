class_name PilotCommand
extends RefCounted

var pitch: float = 0.0
var yaw: float = 0.0
var roll: float = 0.0
var collective: float = 0.0
var strafe: Vector3 = Vector3.ZERO
var transition: float = 0.0
var brake: float = 0.0


func sanitized() -> PilotCommand:
	var clean := PilotCommand.new()
	clean.pitch = clampf(_finite_or_zero(pitch), -1.0, 1.0)
	clean.yaw = clampf(_finite_or_zero(yaw), -1.0, 1.0)
	clean.roll = clampf(_finite_or_zero(roll), -1.0, 1.0)
	clean.collective = clampf(_finite_or_zero(collective), 0.0, 1.0)
	clean.strafe = Vector3(
		_finite_or_zero(strafe.x),
		_finite_or_zero(strafe.y),
		_finite_or_zero(strafe.z)
	)
	if clean.strafe.length_squared() > 1.0:
		clean.strafe = clean.strafe.normalized()
	clean.transition = clampf(_finite_or_zero(transition), 0.0, 1.0)
	clean.brake = clampf(_finite_or_zero(brake), 0.0, 1.0)
	return clean


func _finite_or_zero(value: float) -> float:
	return value if is_finite(value) else 0.0
