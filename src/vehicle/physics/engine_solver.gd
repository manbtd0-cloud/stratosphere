class_name EngineSolver
extends RefCounted
static func torque_at(config:EngineConfig,rpm:float)->float:
	var r=clampf(rpm,config.idle_rpm,config.limiter_rpm);var c=config.torque_curve
	for i in range(c.size()-1):
		if r<=c[i+1].x:return lerpf(c[i].y,c[i+1].y,inverse_lerp(c[i].x,c[i+1].x,r))
	return c[-1].y
static func requested_torque(config:EngineConfig,rpm:float,throttle:float)->float:
	if rpm>=config.limiter_rpm:return 0.0
	return torque_at(config,rpm)*clampf(throttle,0,1)-config.engine_brake_torque*(1.0-clampf(throttle,0,1))
