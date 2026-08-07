extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var e=ClutchSolver.engagement(1,false,1000,850)
    if e!=0 or absf(ClutchSolver.transmit(500,1,320))>320:fail("clutch capacity");return
    print("PASS: test_12_clutch")
    quit(0)
