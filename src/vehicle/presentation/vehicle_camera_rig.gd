class_name VehicleCameraRig
extends Node3D
@export var target_path:NodePath
var target:Node3D
var modes:=PackedStringArray(["chase","hood","bumper","cockpit"])
var mode_index:=0
var camera:Camera3D
func _ready()->void:
	target=get_node_or_null(target_path) as Node3D if not target_path.is_empty() else get_parent() as Node3D
	camera=get_node_or_null("Camera3D") as Camera3D
func cycle()->void:mode_index=(mode_index+1)%modes.size()
func current_mode()->StringName:return StringName(modes[mode_index])
func _physics_process(delta:float)->void:
	if Input.is_action_just_pressed("camera_next"):cycle()
	if target==null or camera==null:return
	var anchor_name={"chase":"ChaseAnchor","hood":"HoodAnchor","bumper":"BumperAnchor","cockpit":"CockpitAnchor"}.get(modes[mode_index],"ChaseAnchor")
	var anchor=target.get_node_or_null("CameraAnchors/%s"%anchor_name) as Node3D
	var look=target.get_node_or_null("CameraAnchors/LookTarget") as Node3D
	if anchor==null:return
	var desired=anchor.global_position
	if modes[mode_index]=="chase":desired=_collision_safe_position(look.global_position if look else target.global_position,desired,target)
	global_position=global_position.lerp(desired,1.0-exp(-10.0*delta))
	if look:look_at(look.global_position,Vector3.UP)
	camera.fov=clampf(72.0+(target.get("linear_velocity") as Vector3).length()*.18 if target is RigidBody3D else 72.0,72.0,88.0)
func _collision_safe_position(origin:Vector3,desired:Vector3,exclude:Object)->Vector3:
	if not is_inside_tree():return desired
	var q=PhysicsRayQueryParameters3D.create(origin,desired);if exclude is CollisionObject3D:q.exclude=[(exclude as CollisionObject3D).get_rid()]
	var hit=get_world_3d().direct_space_state.intersect_ray(q);return hit.position+hit.normal*.2 if not hit.is_empty() else desired
