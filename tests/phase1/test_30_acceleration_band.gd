extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.debug_force_override=true
    for i in 120:await physics_frame
    c.debug_throttle=1;var seconds=0.0
    while c.linear_velocity.length()<27.777 and seconds<14:
     await physics_frame;seconds+=1.0/120.0
    if seconds<6.0 or seconds>12.0:fail("0-100 outside believable band: %.2f"%seconds);return
    lab.queue_free();await process_frame
    print("PASS: phase1 30_acceleration_band")
    quit(0)
