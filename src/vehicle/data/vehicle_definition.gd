class_name VehicleDefinition
extends Resource
@export var vehicle_id:StringName=&"vehicle.prototype_rwd_coupe"
@export var display_name:="Prototype RWD Coupe"
@export var body:BodyConfig=BodyConfig.new()
@export var suspension:SuspensionConfig=SuspensionConfig.new()
@export var tire:TireConfig=TireConfig.new()
@export var engine:EngineConfig=EngineConfig.new()
@export var transmission:TransmissionConfig=TransmissionConfig.new()
@export var differential:DifferentialConfig=DifferentialConfig.new()
@export var brakes:BrakeConfig=BrakeConfig.new()
@export var assists:AssistConfig=AssistConfig.new()
@export var damage:DamageConfig=DamageConfig.new()
@export var aero:AeroConfig=AeroConfig.new()
@export var wheel_radius:=0.306
func validation_errors()->PackedStringArray:
	var e=PackedStringArray();
	if body.mass_kg<=0:e.append("mass must be positive")
	if body.wheelbase<=0 or body.track_width<=0:e.append("vehicle geometry must be positive")
	if suspension.rest_length<=0 or suspension.spring_rate<=0:e.append("suspension values must be positive")
	if engine.torque_curve.size()<2:e.append("torque curve must contain at least two points")
	if transmission.final_drive<=0 or transmission.forward_ratios.is_empty():e.append("transmission ratios invalid")
	if brakes.front_bias<.45 or brakes.front_bias>.8:e.append("brake bias invalid")
	if wheel_radius<=0:e.append("wheel radius invalid")
	return e
func fingerprint()->String:
	var payload="%s|%.3f|%.3f|%.3f|%.3f"%[vehicle_id,body.mass_kg,body.wheelbase,wheel_radius,engine.redline_rpm];return payload.sha256_text()
