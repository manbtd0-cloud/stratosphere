extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=SuspensionConfig.new()
    var comp=SuspensionSolver.force(c,.05,-1)
    var rebound=SuspensionSolver.force(c,.05,1)
    if comp<=rebound:fail("compression velocity should add support");return
    print("PASS: test_02_suspension_damping")
    quit(0)
