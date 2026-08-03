class_name TestFlightFeedback
extends TestCase


func test_engine_intensity_uses_collective_transition_and_thrust() -> void:
	TestAssert.is_near(
		FlightFeedback.calculate_engine_intensity(0.0, 0.0, 0.0),
		0.0,
		0.000001
	)
	TestAssert.is_near(
		FlightFeedback.calculate_engine_intensity(1.0, 1.0, 72000.0),
		1.0,
		0.000001
	)
	TestAssert.is_near(
		FlightFeedback.calculate_engine_intensity(0.5, 0.0, 36000.0),
		0.425,
		0.000001
	)


func test_wind_intensity_rises_smoothly_with_speed() -> void:
	var stopped := FlightFeedback.calculate_wind_intensity(0.0)
	var cruise := FlightFeedback.calculate_wind_intensity(120.0)
	var maximum := FlightFeedback.calculate_wind_intensity(240.0)

	TestAssert.is_equal(stopped, 0.0)
	TestAssert.is_true(cruise > stopped)
	TestAssert.is_true(cruise < maximum)
	TestAssert.is_equal(maximum, 1.0)


func test_exhaust_length_has_visible_idle_and_bounded_maximum() -> void:
	TestAssert.is_near(FlightFeedback.calculate_exhaust_length(0.0), 0.35, 0.000001)
	TestAssert.is_near(FlightFeedback.calculate_exhaust_length(1.0), 3.2, 0.000001)
	TestAssert.is_near(FlightFeedback.calculate_exhaust_length(4.0), 3.2, 0.000001)


func test_audio_shutdown_releases_generator_playbacks() -> void:
	var packed: PackedScene = load("res://scenes/craft/frontier_vtol.tscn")
	var craft := packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(craft)

	var feedback := craft.get_node("FlightFeedback") as FlightFeedback
	var engine_audio := feedback.get_node("EngineAudio") as AudioStreamPlayer3D
	var wind_audio := feedback.get_node("WindAudio") as AudioStreamPlayer3D

	TestAssert.is_true(feedback.has_active_audio_playback())
	feedback.shutdown_audio()
	TestAssert.is_true(not feedback.has_active_audio_playback())
	TestAssert.is_true(not engine_audio.playing)
	TestAssert.is_true(not wind_audio.playing)
	TestAssert.is_equal(engine_audio.stream, null)
	TestAssert.is_equal(wind_audio.stream, null)

	tree.root.remove_child(craft)
	craft.free()


func test_environment_scene_contains_scale_landmarks_and_runway_lights() -> void:
	var packed: PackedScene = load("res://scenes/flight_room/flight_room_environment.tscn")
	var environment := packed.instantiate()

	TestAssert.is_true(environment.get_node_or_null("Ground") != null)
	TestAssert.is_true(environment.get_node_or_null("Runway") != null)
	TestAssert.is_true(environment.get_node_or_null("RunwayLights").get_child_count() >= 8)
	TestAssert.is_true(environment.get_node_or_null("Landmarks").get_child_count() >= 6)

	environment.free()