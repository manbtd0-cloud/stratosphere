extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var d=VehicleDefinition.new()
    if not d.validation_errors().is_empty() or d.body.mass_kg!=1180 or absf(d.body.wheelbase-2.45)>.001:fail("prototype definition");return
    print("PASS: test_22_vehicle_definition")
    quit(0)
