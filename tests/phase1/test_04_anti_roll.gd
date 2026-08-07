extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var x=SuspensionSolver.anti_roll(7000,.10,.05)
    if not is_equal_approx(x.x,-x.y) or x.x>=0:fail("anti-roll conservation");return
    print("PASS: test_04_anti_roll")
    quit(0)
