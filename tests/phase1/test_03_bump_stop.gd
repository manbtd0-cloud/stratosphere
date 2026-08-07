extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=SuspensionConfig.new()
    if SuspensionSolver.force(c,.12,0)<=SuspensionSolver.force(c,.08,0):fail("bump stop not progressive");return
    print("PASS: test_03_bump_stop")
    quit(0)
