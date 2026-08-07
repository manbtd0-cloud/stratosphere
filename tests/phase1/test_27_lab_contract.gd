extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab)
    await physics_frame
    for n in VehicleLabBuilder.ZONES:
     if lab.get_node_or_null(n)==null:fail("missing lab zone "+n);return
    if lab.get_node_or_null("PrototypeRwdCoupe")==null or lab.get_node_or_null("TelemetryOverlay")==null:fail("lab presentation contract");return
    lab.queue_free();await process_frame
    print("PASS: phase1 27_lab_contract")
    quit(0)
