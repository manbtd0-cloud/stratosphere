extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.global_position=Vector3(180,.7,-180);c.debug_force_override=true
    for i in 120:await physics_frame
    c.debug_throttle=.6;c.debug_steer=.32
    for i in 600:await physics_frame
    if not c.global_position.is_finite() or not c.linear_velocity.is_finite() or absf(c.rotation.z)>1.25 or c.global_position.y<-1:fail("handling instability");return
    lab.queue_free();await process_frame
    print("PASS: phase1 39_handling_stability")
    quit(0)
