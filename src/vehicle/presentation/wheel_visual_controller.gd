class_name WheelVisualController
extends Node
@export var vehicle_path:NodePath=NodePath("..")
func _physics_process(_delta:float)->void:
	var vehicle=get_node_or_null(vehicle_path)
	if vehicle==null:return
	var data:Dictionary=vehicle.get_telemetry_snapshot()
	var wheels:Dictionary=data.get("wheels",{})
	for id in ["fl","fr","rl","rr"]:
		var node=get_node_or_null("../VisualRoot/WheelVisual%s"%id.to_upper()) as Node3D
		if node==null:continue
		var wd:Dictionary=wheels.get(id,{})
		var base_z=-1.1515 if id in ["fl","fr"] else 1.2985
		node.position.y=-0.32-float(wd.get("compression",0.0))
		node.position.z=base_z
		if id in ["fl","fr"]:node.rotation.y=float(data.get("steering_angle_rad",0.0))
	var sw=get_node_or_null("../VisualRoot/BodyInterior/SteeringWheelPivot") as Node3D
	if sw:sw.rotation.z=-float(data.get("steering_angle_rad",0.0))*9.0
