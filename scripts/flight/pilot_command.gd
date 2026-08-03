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
	clean.pitch = clampf(pitch, -1.0, 1.0)
	clean.yaw = clampf(yaw, -1.0, 1.0)
	clean.roll = clampf(roll, -1.0, 1.0)
	clean.collective = clampf(collective, 0.0, 1.0)
	clean.strafe = strafe
	if clean.strafe.length_squared() > 1.0:
		clean.strafe = clean.strafe.normalized()
	clean.transition = clampf(transition, 0.0, 1.0)
	clean.brake = clampf(brake, 0.0, 1.0)
	return clean
