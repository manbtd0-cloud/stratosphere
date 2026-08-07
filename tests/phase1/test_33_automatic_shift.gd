extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.debug_force_override=true
    for i in 120:await physics_frame
    c.debug_throttle=1;var highest=1;var last=1
    for i in 1200:
     await physics_frame
     highest=maxi(highest,c.current_gear)
     if c.current_gear<last and c.linear_velocity.length()>8:fail("automatic gearbox hunted down");return
     last=c.current_gear
    if highest<2:fail("automatic gearbox never upshifted");return
    lab.queue_free();await process_frame
    print("PASS: phase1 33_automatic_shift")
    quit(0)
