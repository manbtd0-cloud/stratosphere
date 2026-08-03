class_name TestFlightHud
extends TestCase


func test_speed_formats_as_rounded_kilometers_per_hour() -> void:
	TestAssert.is_equal(FlightHud.format_speed_kmh(10.0), "36 km/h")
	TestAssert.is_equal(FlightHud.format_speed_kmh(-4.0), "0 km/h")


func test_vertical_speed_keeps_sign_and_one_decimal() -> void:
	TestAssert.is_equal(FlightHud.format_vertical_speed(3.25), "+3.3 m/s")
	TestAssert.is_equal(FlightHud.format_vertical_speed(-2.04), "-2.0 m/s")


func test_percent_clamps_and_rounds() -> void:
	TestAssert.is_equal(FlightHud.format_percent(0.376), "38%")
	TestAssert.is_equal(FlightHud.format_percent(-1.0), "0%")
	TestAssert.is_equal(FlightHud.format_percent(2.0), "100%")


func test_hud_scene_contains_required_readouts() -> void:
	var packed: PackedScene = load("res://scenes/ui/flight_hud.tscn")
	var hud := packed.instantiate()
	var readouts := hud.get_node("Margin/ReadoutPanel/Readouts")

	for label_name in [
		"SpeedLabel",
		"AltitudeLabel",
		"VerticalSpeedLabel",
		"CollectiveLabel",
		"TransitionLabel",
		"RouteLabel",
		"StateLabel",
	]:
		TestAssert.is_true(readouts.get_node_or_null(label_name) != null)

	hud.free()