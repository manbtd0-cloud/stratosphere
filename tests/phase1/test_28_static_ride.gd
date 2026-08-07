extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.debug_force_override=true
    for i in 180:await physics_frame
    var t=c.get_telemetry_snapshot();if c.global_position.y<.40 or c.global_position.y>.65:fail("ride height outside band");return
    for id in ["fl","fr","rl","rr"]:
     if not t.wheels[id].grounded:fail("wheel not grounded "+id);return
    if t.damage.severity>.01:fail("normal settling caused damage");return
    lab.queue_free();await process_frame
    print("PASS: phase1 28_static_ride")
    quit(0)
