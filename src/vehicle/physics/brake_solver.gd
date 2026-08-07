class_name BrakeSolver
extends RefCounted
static func axle_torque(config:BrakeConfig,pedal:float,front:bool)->float:
	var share=config.front_bias if front else 1.0-config.front_bias;return config.max_brake_torque*clampf(pedal,0,1)*share*2.0
static func abs_factor(config:BrakeConfig,slip_ratio:float,previous:float,delta:float)->float:
	var target=config.abs_min_factor if slip_ratio < -config.abs_slip_threshold else 1.0;var rate=18.0 if target<previous else 8.0;return move_toward(previous,target,rate*delta)
