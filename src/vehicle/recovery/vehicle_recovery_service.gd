class_name VehicleRecoveryService
extends RefCounted
static func reset_vehicle(body:RigidBody3D,transform:Transform3D)->void:
	body.global_transform=transform;body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO;body.reset_physics_interpolation()
