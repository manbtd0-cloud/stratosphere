extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var v=load("res://scenes/vehicle/prototype_rwd_coupe.tscn").instantiate() as VehicleController;root.add_child(v);await physics_frame;v.debug_force_override=true;v.apply_damage_impulse(v.definition.damage.severe_impulse)
    for i in 2:await physics_frame
    var t=v.get_telemetry_snapshot();if t.damage.severity<.9 or t.damage.power_multiplier>=1:fail("damage not in live telemetry");return
    v.repair();if v.damage_state.severity!=0:fail("repair failed");return
    v.queue_free();await process_frame
    print("PASS: phase1 38_damage_integration")
    quit(0)
