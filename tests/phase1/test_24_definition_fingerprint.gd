extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var a=VehicleDefinition.new();var b=VehicleDefinition.new()
    if a.fingerprint()!=b.fingerprint() or a.fingerprint().length()!=64:fail("definition fingerprint");return
    print("PASS: test_24_definition_fingerprint")
    quit(0)
