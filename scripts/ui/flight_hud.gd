class_name FlightHud
extends CanvasLayer

@onready var _speed_label: Label = $Margin/ReadoutPanel/Readouts/SpeedLabel
@onready var _altitude_label: Label = $Margin/ReadoutPanel/Readouts/AltitudeLabel
@onready var _vertical_speed_label: Label = $Margin/ReadoutPanel/Readouts/VerticalSpeedLabel
@onready var _collective_label: Label = $Margin/ReadoutPanel/Readouts/CollectiveLabel
@onready var _transition_label: Label = $Margin/ReadoutPanel/Readouts/TransitionLabel
@onready var _route_label: Label = $Margin/ReadoutPanel/Readouts/RouteLabel
@onready var _state_label: Label = $Margin/ReadoutPanel/Readouts/StateLabel


static func format_speed_kmh(speed_mps: float) -> String:
	return "%d km/h" % roundi(maxf(speed_mps, 0.0) * 3.6)


static func format_vertical_speed(vertical_speed_mps: float) -> String:
	var magnitude := floor(absf(vertical_speed_mps) * 10.0 + 0.5) / 10.0
	var rounded_value := -magnitude if vertical_speed_mps < 0.0 else magnitude
	if is_zero_approx(rounded_value):
		rounded_value = 0.0
	return "%+.1f m/s" % rounded_value


static func format_percent(unit_value: float) -> String:
	return "%d%%" % roundi(clampf(unit_value, 0.0, 1.0) * 100.0)


func update_telemetry(telemetry: Dictionary) -> void:
	if not is_node_ready():
		return
	_speed_label.text = "SPD  " + format_speed_kmh(float(telemetry.get("speed_mps", 0.0)))
	_altitude_label.text = "ALT  %d m" % roundi(maxf(float(telemetry.get("altitude_m", 0.0)), 0.0))
	_vertical_speed_label.text = "V/S  " + format_vertical_speed(
		float(telemetry.get("vertical_speed_mps", 0.0))
	)
	_collective_label.text = "COL  " + format_percent(float(telemetry.get("collective", 0.0)))
	_transition_label.text = "VEC  " + format_percent(float(telemetry.get("transition", 0.0)))


func set_route_progress(passed_gates: int, total_gates: int) -> void:
	if not is_node_ready():
		return
	_route_label.text = "ROUTE  %d / %d" % [passed_gates, total_gates]


func set_state(state: int) -> void:
	if not is_node_ready():
		return
	match state:
		FlightRoomController.STATE_CRASHED:
			_state_label.text = "CRAFT LOST — F5 RESTART"
		FlightRoomController.STATE_COMPLETED:
			_state_label.text = "ROUTE COMPLETE"
		_:
			_state_label.text = "FLIGHT ACTIVE"
