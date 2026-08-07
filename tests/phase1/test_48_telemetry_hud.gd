extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
	var hud=CanvasLayer.new();hud.set_script(load("res://src/vehicle/telemetry/telemetry_overlay.gd"));root.add_child(hud)
	await process_frame
	hud.apply_snapshot({"speed_mps":34.2,"engine_rpm":5120.0,"gear":3,"tcs_factor":0.74,"steering_angle_rad":0.12,"damage":{"severity":0.18},"wheels":{"fl":{"slip_ratio":0.08,"surface":"asphalt_dry","normal_load":3100.0},"fr":{"slip_ratio":0.07,"surface":"asphalt_dry","normal_load":3050.0},"rl":{"slip_ratio":0.14,"surface":"asphalt_dry","normal_load":2950.0},"rr":{"slip_ratio":0.13,"surface":"asphalt_dry","normal_load":2920.0}}})
	for path in ["HudRoot/SpeedPanel/Speed","HudRoot/SpeedPanel/Gear","HudRoot/StatusPanel/Rpm","HudRoot/StatusPanel/Assists","HudRoot/WheelPanel/FL","HudRoot/WheelPanel/FR","HudRoot/WheelPanel/RL","HudRoot/WheelPanel/RR"]:
		if hud.get_node_or_null(path)==null:fail("missing HUD element: %s"%path);return
	var speed=(hud.get_node("HudRoot/SpeedPanel/Speed") as Label).text
	var gear=(hud.get_node("HudRoot/SpeedPanel/Gear") as Label).text
	var wheel=(hud.get_node("HudRoot/WheelPanel/RL") as Label).text
	if not speed.contains("123"):fail("speed readout must show km/h telemetry");return
	if not gear.contains("3"):fail("gear readout must show active gear");return
	if not wheel.contains("0.14") or not wheel.contains("asphalt_dry"):fail("wheel panel must expose slip and surface");return
	hud.queue_free();await process_frame
	print("PASS: phase1 48_telemetry_hud")
	quit(0)
