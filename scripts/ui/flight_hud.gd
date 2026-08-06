class_name FlightHud
extends CanvasLayer

const CONTROL_CUE_RADIUS: float = 32.0

@onready var _speed_label: Label = $Margin/ReadoutPanel/Readouts/SpeedLabel
@onready var _altitude_label: Label = $Margin/ReadoutPanel/Readouts/AltitudeLabel
@onready var _vertical_speed_label: Label = $Margin/ReadoutPanel/Readouts/VerticalSpeedLabel
@onready var _collective_label: Label = $Margin/ReadoutPanel/Readouts/CollectiveLabel
@onready var _transition_label: Label = $Margin/ReadoutPanel/Readouts/TransitionLabel
@onready var _route_label: Label = $Margin/ReadoutPanel/Readouts/RouteLabel
@onready var _state_label: Label = $Margin/ReadoutPanel/Readouts/StateLabel
@onready var _control_demand_cue: Control = $ControlDemandCue
@onready var _demand_marker: Label = $ControlDemandCue/DemandMarker

var _camera_mode: int = FlightCameraRig.MODE_CHASE


static func format_speed_kmh(speed_mps: float) -> String:
	return "%d km/h" % roundi(maxf(speed_mps, 0.0) * 3.6)


static func format_vertical_speed(vertical_speed_mps: float) -> String:
	var magnitude: float = floorf(absf(vertical_speed_mps) * 10.0 + 0.5) / 10.0
	var rounded_value: float = -magnitude if vertical_speed_mps < 0.0 else magnitude
	if is_zero_approx(rounded_value):
		rounded_value = 0.0
	return "%+.1f m/s" % rounded_value


static func format_percent(unit_value: float) -> String:
	return "%d%%" % roundi(clampf(unit_value, 0.0, 1.0) * 100.0)


static func control_marker_offset(demand: Vector2, radius: float) -> Vector2:
	var safe := Vector2(
		demand.x if is_finite(demand.x) else 0.0,
		demand.y if is_finite(demand.y) else 0.0
	)
	return safe.limit_length(maxf(radius, 0.0))


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


func set_control_demand(demand: Vector2) -> void:
	if not is_node_ready():
		return
	var safe_demand := Vector2(
		demand.x if is_finite(demand.x) else 0.0,
		demand.y if is_finite(demand.y) else 0.0
	)
	var offset := control_marker_offset(
		safe_demand * CONTROL_CUE_RADIUS,
		CONTROL_CUE_RADIUS
	)
	_demand_marker.position = Vector2(32.0, 27.0) + offset
	_demand_marker.modulate.a = 0.35 + clampf(safe_demand.length(), 0.0, 1.0) * 0.65


func set_camera_mode(mode: int) -> void:
	_camera_mode = mode
	if is_node_ready():
		_control_demand_cue.modulate.a = (
			0.35 if mode == FlightCameraRig.MODE_COCKPIT else 1.0
		)


func get_camera_mode_for_test() -> int:
	return _camera_mode
