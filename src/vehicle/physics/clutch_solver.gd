class_name ClutchSolver
extends RefCounted
static func engagement(manual_pedal:float,automatic:bool,engine_rpm:float,idle_rpm:float)->float:
	if not automatic:return 1.0-clampf(manual_pedal,0,1)
	return clampf(inverse_lerp(idle_rpm*.8,idle_rpm*2.2,engine_rpm),.18,1.0)
static func transmit(requested_torque:float,engagement_factor:float,capacity_nm:float)->float:return clampf(requested_torque*clampf(engagement_factor,0,1),-capacity_nm,capacity_nm)
