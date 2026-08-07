extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=SuspensionConfig.new()
    if SuspensionSolver.force(c,.09,0)<=2500:fail("spring support too low");return
    print("PASS: test_01_suspension_support")
    quit(0)
