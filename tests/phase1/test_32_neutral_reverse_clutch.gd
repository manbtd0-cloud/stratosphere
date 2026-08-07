extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.debug_force_override=true;c.automatic_transmission=false
    for i in 120:await physics_frame
    c.set_gear_immediate(0);c.debug_throttle=1
    for i in 120:await physics_frame
    if c.linear_velocity.length()>.6:fail("neutral propelled car");return
    c.reset_vehicle();c.set_gear_immediate(1);c.debug_clutch=1
    for i in 120:await physics_frame
    if c.linear_velocity.length()>.6:fail("clutch-down propelled car");return
    c.debug_clutch=0
    for i in 120:await physics_frame
    if (-c.global_basis.z).dot(c.linear_velocity)<1:fail("released clutch did not propel forward");return
    c.reset_vehicle();c.set_gear_immediate(-1);c.debug_clutch=0
    for i in 180:await physics_frame
    if (-c.global_basis.z).dot(c.linear_velocity)>-1:fail("reverse did not move backward");return
    lab.queue_free();await process_frame
    print("PASS: phase1 32_neutral_reverse_clutch")
    quit(0)
