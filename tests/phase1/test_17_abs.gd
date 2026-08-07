extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=BrakeConfig.new();var f=BrakeSolver.abs_factor(c,-.8,1,.1)
    if f>=1 or f<c.abs_min_factor:fail("ABS modulation");return
    print("PASS: test_17_abs")
    quit(0)
