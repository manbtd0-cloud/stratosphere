extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
    var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.debug_force_override=true
    for i in 120:await physics_frame
    c.debug_throttle=.65;var grounded=0;var samples=0
    for i in 600:
     await physics_frame
     if i%10==0:
      samples+=1;var t=c.get_telemetry_snapshot();var n=0;for id in ["fl","fr","rl","rr"]:n+=1 if t.wheels[id].grounded else 0
      if n==4:grounded+=1
    if float(grounded)/samples<.9 or c.global_position.y<.3:fail("persistent ground contact %.2f"%(float(grounded)/samples));return
    lab.queue_free();await process_frame
    print("PASS: phase1 40_ground_contact")
    quit(0)
