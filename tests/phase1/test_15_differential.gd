extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=DifferentialConfig.new();var x=DifferentialSolver.split(1000,10,20,c)
    if absf(x.x+x.y-1000)>.01:fail("differential torque conservation");return
    print("PASS: test_15_differential")
    quit(0)
