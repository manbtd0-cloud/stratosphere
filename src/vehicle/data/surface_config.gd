class_name SurfaceConfig
extends Resource
@export var id:StringName=&"asphalt_dry"
@export var friction_multiplier:=1.0
@export var optimal_slip_multiplier:=1.0
@export var rolling_resistance_coefficient:=0.012
@export var wetness:=0.0
static func for_id(surface_id:StringName)->SurfaceConfig:
	var r=SurfaceConfig.new();r.id=surface_id
	match surface_id:
		&"asphalt_wet":r.friction_multiplier=.76;r.optimal_slip_multiplier=1.18;r.rolling_resistance_coefficient=.014;r.wetness=1.0
		&"gravel":r.friction_multiplier=.62;r.optimal_slip_multiplier=1.6;r.rolling_resistance_coefficient=.035
		&"dirt":r.friction_multiplier=.55;r.optimal_slip_multiplier=1.8;r.rolling_resistance_coefficient=.045
		&"grass":r.friction_multiplier=.46;r.optimal_slip_multiplier=1.9;r.rolling_resistance_coefficient=.06
	return r
