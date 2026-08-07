class_name TelemetryOverlay
extends CanvasLayer

@export var vehicle_path: NodePath

var speed_label: Label
var gear_label: Label
var rpm_label: Label
var assists_label: Label
var wheel_labels: Dictionary = {}

func _ready() -> void:
	var root := Control.new()
	root.name = "HudRoot"
	root.position = Vector2(18, 18)
	root.size = Vector2(430, 248)
	add_child(root)

	var backdrop := Panel.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.018, 0.022, 0.028, 0.88)
	panel_style.border_color = Color(0.28, 0.34, 0.42, 0.72)
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	backdrop.add_theme_stylebox_override("panel", panel_style)
	root.add_child(backdrop)

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(16, 10)
	title.text = "VEHICLE LAB // LIVE TELEMETRY"
	title.add_theme_font_size_override("font_size", 13)
	title.modulate = Color(0.68, 0.76, 0.86)
	root.add_child(title)

	var speed_panel := VBoxContainer.new()
	speed_panel.name = "SpeedPanel"
	speed_panel.position = Vector2(16, 36)
	speed_panel.size = Vector2(150, 92)
	root.add_child(speed_panel)
	speed_label = _label("Speed", "--- km/h", 31)
	speed_panel.add_child(speed_label)
	gear_label = _label("Gear", "GEAR -", 20)
	gear_label.modulate = Color(0.94, 0.78, 0.38)
	speed_panel.add_child(gear_label)

	var status_panel := VBoxContainer.new()
	status_panel.name = "StatusPanel"
	status_panel.position = Vector2(180, 40)
	status_panel.size = Vector2(230, 84)
	root.add_child(status_panel)
	rpm_label = _label("Rpm", "RPM ----", 17)
	status_panel.add_child(rpm_label)
	assists_label = _label("Assists", "TCS --  DMG --", 14)
	assists_label.modulate = Color(0.72, 0.80, 0.88)
	status_panel.add_child(assists_label)

	var divider := ColorRect.new()
	divider.name = "Divider"
	divider.position = Vector2(16, 132)
	divider.size = Vector2(398, 1)
	divider.color = Color(0.28, 0.34, 0.42, 0.55)
	root.add_child(divider)

	var wheel_panel := GridContainer.new()
	wheel_panel.name = "WheelPanel"
	wheel_panel.columns = 2
	wheel_panel.position = Vector2(16, 142)
	wheel_panel.size = Vector2(398, 90)
	wheel_panel.add_theme_constant_override("h_separation", 18)
	wheel_panel.add_theme_constant_override("v_separation", 5)
	root.add_child(wheel_panel)
	for id in ["FL", "FR", "RL", "RR"]:
		var label := _label(id, "%s  slip --  load --  ---" % id, 13)
		label.custom_minimum_size = Vector2(188, 34)
		wheel_panel.add_child(label)
		wheel_labels[id.to_lower()] = label

func _label(name: String, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = name
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = Color(0.92, 0.94, 0.97)
	return label

func _process(_delta: float) -> void:
	var vehicle = get_node_or_null(vehicle_path)
	if vehicle == null:
		return
	apply_snapshot(vehicle.get_telemetry_snapshot())

func apply_snapshot(telemetry: Dictionary) -> void:
	if speed_label == null:
		return
	var speed_kmh := float(telemetry.get("speed_mps", 0.0)) * 3.6
	speed_label.text = "%03d km/h" % int(round(speed_kmh))
	var gear := int(telemetry.get("gear", 0))
	gear_label.text = "GEAR %s" % _gear_text(gear)
	rpm_label.text = "RPM %04d" % int(round(float(telemetry.get("engine_rpm", 0.0))))
	var damage: Dictionary = telemetry.get("damage", {})
	assists_label.text = "TCS %.2f   STEER %+4.1f°   DMG %3.0f%%" % [
		float(telemetry.get("tcs_factor", 1.0)),
		rad_to_deg(float(telemetry.get("steering_angle_rad", 0.0))),
		float(damage.get("severity", 0.0)) * 100.0,
	]
	var wheels: Dictionary = telemetry.get("wheels", {})
	for id in ["fl", "fr", "rl", "rr"]:
		var wheel: Dictionary = wheels.get(id, {})
		var label := wheel_labels.get(id) as Label
		if label == null:
			continue
		label.text = "%s  slip %+0.2f  %4.1fkN\n     %s" % [
			id.to_upper(),
			float(wheel.get("slip_ratio", 0.0)),
			float(wheel.get("normal_load", 0.0)) / 1000.0,
			String(wheel.get("surface", "air")),
		]

func _gear_text(gear: int) -> String:
	if gear < 0:
		return "R"
	if gear == 0:
		return "N"
	return str(gear)
