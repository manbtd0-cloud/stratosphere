extends SceneTree

func fail(message:String)->void:
    push_error("FAIL: %s" % message)
    quit(1)

func _init()->void:
    call_deferred("run")

func run()->void:
    var visual_script_path := "res://src/vehicle/presentation/vehicle_visual_rig.gd"
    if not FileAccess.file_exists(visual_script_path):
        fail("350Z visual rig script must exist")
        return
    var packed = load("res://scenes/vehicle/prototype_rwd_coupe.tscn")
    if packed == null:
        fail("prototype vehicle scene must load")
        return
    var vehicle = packed.instantiate()
    root.add_child(vehicle)
    await process_frame
    var rig = vehicle.get_node_or_null("VisualRoot/VehicleVisualRig")
    var fallback = vehicle.get_node_or_null("VisualRoot/GreyboxFallback") as Node3D
    if rig == null or fallback == null:
        fail("vehicle scene must contain runtime visual rig and greybox fallback")
        return
    if str(rig.runtime_root) != "res://assets/runtime/vehicle/prototype_rwd_coupe":
        fail("runtime visual path contract changed")
        return
    if absf(float(rig.model_yaw_degrees) - 180.0) > 0.001 or absf(float(rig.model_vertical_offset) + 0.39) > 0.001:
        fail("audited 350Z presentation transform changed")
        return
    var definition = vehicle.get("definition")
    if definition == null or absf(float(definition.body.wheelbase) - 2.66645) > 0.0001 or absf(float(definition.body.track_width) - 1.56642) > 0.0001:
        fail("vehicle scene must use audited 350Z wheelbase and track")
        return
    for path in ["WheelAnchors/WheelFL", "WheelAnchors/WheelFR", "WheelAnchors/WheelRL", "WheelAnchors/WheelRR"]:
        if vehicle.get_node_or_null(path) == null:
            fail("missing audited wheel anchor: %s" % path)
            return
    if rig.is_runtime_visual_loaded():
        if fallback.visible:
            fail("greybox must hide when runtime 350Z exists")
            return
        for semantic in ["body_exterior", "cockpit_static", "glass_static", "steering_wheel_visual"]:
            if rig.get_semantic_node(semantic) == null:
                fail("loaded runtime visual missing semantic: %s" % semantic)
                return
        for id in ["fl", "fr", "rl", "rr"]:
            if rig.get_physical_wheel_node(id) == null:
                fail("loaded runtime visual missing physical wheel binding: %s" % id)
                return
    elif not fallback.visible:
        fail("greybox must remain visible when runtime 350Z files are absent")
        return
    vehicle.queue_free()
    await process_frame
    print("PASS: phase1 43_350z_visual_binding")
    quit(0)
