extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var d=VehicleDefinition.new();d.body.mass_kg=-1
    if VehicleDefinitionValidator.validate(d).is_empty():fail("invalid mass accepted");return
    print("PASS: test_23_definition_validation")
    quit(0)
