extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var r=InputRouter.new()
    if not InputMap.has_action("drive_clutch"):fail("clutch input missing");return
    r.free()
    print("PASS: test_25_input_clutch")
    quit(0)
