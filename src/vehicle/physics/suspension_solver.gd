class_name SuspensionSolver
extends RefCounted
static func force(config:SuspensionConfig,compression:float,suspension_velocity:float)->float:
	var c=clampf(compression,0.0,config.max_compression);var spring=c*config.spring_rate;var damping=(-suspension_velocity)*(config.compression_damping if suspension_velocity<0.0 else config.rebound_damping);var bump=0.0
	if c>config.bump_stop_start:var x=c-config.bump_stop_start;bump=x*x*config.bump_stop_rate/maxf(config.max_compression-config.bump_stop_start,.001)
	return maxf(spring+damping+bump,0.0)
static func anti_roll(rate:float,left_compression:float,right_compression:float)->Vector2:
	var transfer=(left_compression-right_compression)*rate;return Vector2(-transfer,transfer)
