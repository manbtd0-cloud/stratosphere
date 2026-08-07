extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.debug_force_override=true
    for i in 120:await physics_frame
    c.debug_throttle=1
    for i in 240:await physics_frame
    if c.linear_velocity.length()<5.0:fail("two-second launch too weak");return
    if c.tcs_factor<=0 or c.tcs_factor>1:fail("TCS factor invalid");return
    lab.queue_free();await process_frame
    print("PASS: phase1 29_early_launch")
    quit(0)
