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