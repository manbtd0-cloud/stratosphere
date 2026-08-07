class_name VehicleTelemetry
extends RefCounted
var sample:Dictionary={}
func update(values:Dictionary)->void: sample=values.duplicate(true)
func get_snapshot()->Dictionary:return sample.duplicate(true)
