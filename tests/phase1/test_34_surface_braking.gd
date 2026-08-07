extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var packed=load("res://scenes/vehicle/prototype_rwd_coupe.tscn")
    var results={}
    for spec in [["dry",Vector3(-18,.7,-260)],["wet",Vector3(18,.7,-260)],["gravel",Vector3(120,.7,80)],["dirt",Vector3(142,.7,80)],["grass",Vector3(164,.7,80)]]:
     var c=packed.instantiate() as VehicleController;lab.add_child(c);c.global_position=spec[1];c.debug_force_override=true
     for i in 80:await physics_frame
     c.linear_velocity=-c.global_basis.z*18.0
     for id in ["fl","fr","rl","rr"]:c.wheel_omega[id]=18.0/c.definition.wheel_radius
     c.debug_brake=1
     for i in 120:await physics_frame
     results[spec[0]]=c.linear_velocity.length();c.queue_free();await process_frame
    if not (results.dry<results.wet and results.wet<results.dirt and results.dry<results.gravel and results.gravel<results.grass):fail("surface braking order %s"%results);return
    lab.queue_free();await process_frame
    print("PASS: phase1 34_surface_braking")
    quit(0)
