class_name DifferentialSolver
extends RefCounted
static func split(input_torque:float,left_speed:float,right_speed:float,config:DifferentialConfig)->Vector2:
	var delta=absf(left_speed-right_speed);var lock=clampf(config.preload_nm+delta*config.power_lock,0.0,absf(input_torque)*.35);var base=input_torque*.5;var direction=signf(right_speed-left_speed)*signf(input_torque);var a=base+direction*lock*.5;return Vector2(a,input_torque-a)
