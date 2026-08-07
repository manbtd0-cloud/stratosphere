extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var scene=load("res://scenes/vehicle/prototype_rwd_coupe.tscn").instantiate()
    root.add_child(scene)
    await physics_frame
    if not scene is VehicleController:fail("root must be custom RigidBody controller");return
    if scene.get_node_or_null("ChassisCollision")==null:fail("chassis collision must be direct child");return
    for path in ["WheelAnchors/WheelFL","WheelAnchors/WheelFR","WheelAnchors/WheelRL","WheelAnchors/WheelRR","CameraAnchors/ChaseAnchor","CameraAnchors/HoodAnchor","CameraAnchors/BumperAnchor","CameraAnchors/CockpitAnchor","CameraAnchors/LookTarget"]:
     if scene.get_node_or_null(path)==null:fail("missing anchor "+path);return
    scene.queue_free()
    await process_frame
    print("PASS: phase1 26_scene_contract")
    quit(0)
