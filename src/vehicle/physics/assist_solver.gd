class_name AssistSolver
extends RefCounted
static func tcs_factor(current:float,slip:float,config:AssistConfig,delta:float)->float:
	var target=0.15 if slip>config.tcs_target_slip else 1.0;return move_toward(current,target,(config.tcs_cut_rate if target<current else config.tcs_recovery_rate)*delta)
static func countersteer(driver:float,slip_angle:float,config:AssistConfig)->float:return clampf(driver-slip_angle*.55,-1.0-config.max_countersteer,1.0+config.max_countersteer)
static func stability(yaw_rate:float,target_yaw:float,config:AssistConfig)->Dictionary:
	var error=yaw_rate-target_yaw;var severity=clampf(absf(error)*.45,0,1);return {"torque_cut":minf(severity,config.max_stability_torque_cut),"brake_left":minf(severity,config.max_stability_brake) if error<0 else 0.0,"brake_right":minf(severity,config.max_stability_brake) if error>0 else 0.0}
