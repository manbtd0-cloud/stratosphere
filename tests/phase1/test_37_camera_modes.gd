extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var v=load("res://scenes/vehicle/prototype_rwd_coupe.tscn").instantiate();root.add_child(v);await physics_frame
    var rig=v.get_node("CameraRig") as VehicleCameraRig;var seen=[]
    for i in 4:seen.append(String(rig.current_mode()));rig.cycle()
    for m in ["chase","hood","bumper","cockpit"]:
     if m not in seen:fail("camera mode missing "+m);return
    v.queue_free();await process_frame
    print("PASS: phase1 37_camera_modes")
    quit(0)
