class_name TestFrontierVtolController
extends TestCase

const REQUIRED_TELEMETRY_KEYS := [
	"speed_mps",
	"altitude_m",
	"transition",
	"collective",
	"vertical_speed_mps",
	"angular_velocity_local_rad_s",
	"grounded",
	"lift_newtons",
	"drag_newtons",
	"thrust_newtons",
]


func test_controller_owns_physics_integration_contract() -> void:
	var craft := FrontierVtolController.new()

	TestAssert.is_true(craft.custom_integrator)
	TestAssert.is_near(craft.mass, 4200.0, 0.000001)
	TestAssert.is_near(craft.gravity_scale, 1.0, 0.000001)
	TestAssert.is_true(craft.contact_monitor)
	TestAssert.is_equal(craft.max_contacts_reported, 8)
	TestAssert.is_true(craft.continuous_cd)

	craft.free()


func test_telemetry_contains_required_keys() -> void:
	var craft := FrontierVtolController.new()
	var telemetry := craft.get_telemetry()

	for key in REQUIRED_TELEMETRY_KEYS:
		TestAssert.is_true(telemetry.has(key), "Missing telemetry key: %s" % key)

	craft.free()


func test_reset_restores_transform_and_clears_velocity() -> void:
	var craft := FrontierVtolController.new()
	craft.transform = Transform3D(Basis.IDENTITY, Vector3(30.0, 40.0, 50.0))
	craft.linear_velocity = Vector3(10.0, -20.0, 30.0)
	craft.angular_velocity = Vector3(1.0, 2.0, 3.0)
	var target := Transform3D(
		Basis.from_euler(Vector3(0.1, 0.2, 0.3)),
		Vector3(2.0, 8.0, -4.0)
	)

	craft.reset_to(target)

	TestAssert.is_equal(craft.transform, target)
	TestAssert.is_equal(craft.linear_velocity, Vector3.ZERO)
	TestAssert.is_equal(craft.angular_velocity, Vector3.ZERO)
	TestAssert.is_true(not craft.is_grounded())

	craft.free()


func test_impact_classification_distinguishes_landing_and_crash() -> void:
	var craft := FrontierVtolController.new()

	TestAssert.is_equal(
		craft.classify_impact(Vector3(1.0, -3.0, 2.0)),
		FrontierVtolController.ContactOutcome.LANDED
	)
	TestAssert.is_equal(
		craft.classify_impact(Vector3(0.0, -13.0, 0.0)),
		FrontierVtolController.ContactOutcome.CRASHED
	)

	craft.free()


func test_craft_scene_contains_required_anchors() -> void:
	var packed: PackedScene = load("res://scenes/craft/frontier_vtol.tscn")
	var craft := packed.instantiate()

	TestAssert.is_true(craft is FrontierVtolController)
	TestAssert.is_true(craft.get_node_or_null("CockpitAnchor") != null)
	TestAssert.is_true(craft.get_node_or_null("ChaseAnchor") != null)
	TestAssert.is_true(craft.get_node_or_null("ForwardMarker") != null)

	craft.free()


func test_craft_scene_instances_generated_vtol_visual() -> void:
	TestAssert.is_true(
		ResourceLoader.exists("res://assets/generated/vtol_blockout.glb"),
		"Generated VTOL GLB must be importable"
	)
	var packed: PackedScene = load("res://scenes/craft/frontier_vtol.tscn")
	var craft := packed.instantiate()
	var visual := craft.get_node_or_null("VisualRoot/GeneratedVTOL")

	TestAssert.is_true(visual != null, "Craft must instance the generated VTOL visual")
	TestAssert.is_true(visual is Node3D)
	TestAssert.is_true(craft.get_node_or_null("CollisionShape3D") != null)

	craft.free()


func test_craft_scene_uses_default_control_profile() -> void:
	var packed: PackedScene = load("res://scenes/craft/frontier_vtol.tscn")
	var craft := packed.instantiate() as FrontierVtolController

	TestAssert.is_true(craft.control_profile != null)
	TestAssert.is_true(
		craft.control_profile.resource_path.ends_with(
			"resources/flight/default_flight_control_profile.tres"
		)
	)
	craft.free()


func test_telemetry_reports_local_angular_velocity() -> void:
	var craft := FrontierVtolController.new()
	craft.angular_velocity = Vector3(1.0, 2.0, 3.0)
	var telemetry := craft.get_telemetry()

	TestAssert.is_true(telemetry.has("angular_velocity_local_rad_s"))
	var local_rate: Vector3 = telemetry["angular_velocity_local_rad_s"]
	TestAssert.is_true(is_finite(local_rate.x))
	TestAssert.is_true(is_finite(local_rate.y))
	TestAssert.is_true(is_finite(local_rate.z))
	craft.free()
