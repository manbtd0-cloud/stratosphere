class_name DamageState
extends Resource
@export var severity:=0.0
@export var power_multiplier:=1.0
@export var grip_multiplier:=1.0
@export var drag_multiplier:=1.0
@export var steering_offset:=0.0
func apply_impulse(impulse:float,config:DamageConfig)->void:
	severity=maxf(severity,clampf(inverse_lerp(config.minor_impulse,config.severe_impulse,impulse),0,1));power_multiplier=1.0-severity*config.max_power_loss;grip_multiplier=1.0-severity*config.max_grip_loss;drag_multiplier=1.0+severity*config.max_drag_increase;steering_offset=severity*config.max_steering_offset
func repair()->void:severity=0;power_multiplier=1;grip_multiplier=1;drag_multiplier=1;steering_offset=0
