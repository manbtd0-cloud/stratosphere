extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.debug_force_override=true;var spawn=c.spawn_transform;c.linear_velocity=Vector3(5,2,-10);c.angular_velocity=Vector3(2,1,3);c.global_position+=Vector3(5,5,5);c.reset_vehicle()
    if c.global_transform.origin.distance_to(spawn.origin)>.01 or c.linear_velocity.length()>.01 or c.angular_velocity.length()>.01:fail("reset state");return
    lab.queue_free();await process_frame
    print("PASS: phase1 36_reset")
    quit(0)
