class_name TestFlightCameraRig
extends TestCase


func test_default_mode_and_toggle_order() -> void:
	var rig := FlightCameraRig.new()

	TestAssert.is_equal(rig.get_mode(), FlightCameraRig.MODE_CHASE)
	TestAssert.is_equal(rig.toggle_mode(), FlightCameraRig.MODE_COCKPIT)
	TestAssert.is_equal(rig.toggle_mode(), FlightCameraRig.MODE_CHASE)

	rig.free()


func test_invalid_mode_is_rejected_without_changing_state() -> void:
	var rig := FlightCameraRig.new()

	TestAssert.is_true(not rig.set_mode(999))
	TestAssert.is_equal(rig.get_mode(), FlightCameraRig.MODE_CHASE)

	rig.free()


func test_rig_binds_to_required_craft_anchors() -> void:
	var craft_scene: PackedScene = load("res://scenes/craft/frontier_vtol.tscn")
	var craft := craft_scene.instantiate()
	var rig := FlightCameraRig.new()

	TestAssert.is_true(rig.bind_to_craft(craft))
	TestAssert.is_true(rig.is_bound())

	rig.free()
	craft.free()


func test_camera_scene_uses_chase_readability_defaults() -> void:
	var rig_scene: PackedScene = load("res://scenes/craft/flight_camera_rig.tscn")
	var rig := rig_scene.instantiate()
	var camera: Camera3D = rig.get_node("Camera3D")

	TestAssert.is_near(camera.fov, 78.0, 0.000001)
	TestAssert.is_near(camera.near, 0.05, 0.000001)
	TestAssert.is_true(camera.current)

	rig.free()


func test_chase_fov_is_monotonic_and_bounded() -> void:
	var rig := FlightCameraRig.new()
	rig.control_profile = FlightControlProfile.new()
	var slow := rig.calculate_chase_fov(0.0)
	var medium := rig.calculate_chase_fov(100.0)
	var fast := rig.calculate_chase_fov(1000.0)

	TestAssert.is_true(medium > slow)
	TestAssert.is_true(fast >= medium)
	TestAssert.is_near(slow, rig.control_profile.min_chase_fov_degrees, 0.000001)
	TestAssert.is_near(fast, rig.control_profile.max_chase_fov_degrees, 0.000001)
	rig.free()


func test_velocity_lookahead_is_bounded() -> void:
	var rig := FlightCameraRig.new()
	rig.control_profile = FlightControlProfile.new()
	rig.control_profile.chase_max_lookahead_meters = 12.0
	var lookahead := rig.calculate_velocity_lookahead(Vector3(1000.0, 0.0, 0.0))

	TestAssert.is_true(lookahead.length() <= 12.0001)
	TestAssert.is_true(lookahead.x > 0.0)
	rig.free()


func test_roll_attenuation_preserves_forward_direction() -> void:
	var rig := FlightCameraRig.new()
	rig.control_profile = FlightControlProfile.new()
	rig.control_profile.chase_roll_follow_amount = 0.25
	var rolled := Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(70.0)))
	var attenuated := rig.attenuate_chase_roll(rolled)

	TestAssert.is_true((-attenuated.z).dot(-rolled.z) > 0.999)
	TestAssert.is_true(absf(attenuated.get_euler().z) < absf(rolled.get_euler().z))
	rig.free()


func test_camera_scene_uses_default_control_profile() -> void:
	var packed: PackedScene = load("res://scenes/craft/flight_camera_rig.tscn")
	var rig := packed.instantiate() as FlightCameraRig

	TestAssert.is_true(rig.control_profile != null)
	TestAssert.is_true(
		rig.control_profile.resource_path.ends_with(
			"resources/flight/default_flight_control_profile.tres"
		)
	)
	rig.free()


func test_chase_lookahead_does_not_move_camera_through_craft() -> void:
	var craft_scene: PackedScene = load("res://scenes/craft/frontier_vtol.tscn")
	var craft := craft_scene.instantiate() as FrontierVtolController
	craft.linear_velocity = Vector3(0.0, 0.0, -1000.0)
	var rig := FlightCameraRig.new()
	rig.control_profile = FlightControlProfile.new()
	TestAssert.is_true(rig.bind_to_craft(craft))
	var chase_anchor := craft.get_node("ChaseAnchor") as Node3D

	rig.snap_to_active_anchor()

	TestAssert.is_near(
		rig.global_transform.origin.distance_to(chase_anchor.global_transform.origin),
		0.0,
		0.000001
	)
	rig.free()
	craft.free()
