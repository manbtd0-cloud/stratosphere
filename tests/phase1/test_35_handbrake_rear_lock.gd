extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.debug_force_override=true
    for i in 120:await physics_frame
    c.linear_velocity=-c.global_basis.z*12;for id in ["fl","fr","rl","rr"]:c.wheel_omega[id]=12/c.definition.wheel_radius
    c.debug_handbrake=1
    for i in 60:await physics_frame
    var t=c.get_telemetry_snapshot();if absf(t.wheels.rl.slip_ratio)<=absf(t.wheels.fl.slip_ratio)+.1:fail("handbrake did not preferentially lock rear");return
    lab.queue_free();await process_frame
    print("PASS: phase1 35_handbrake_rear_lock")
    quit(0)
