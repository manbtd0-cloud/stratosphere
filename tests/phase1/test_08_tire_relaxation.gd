extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var x=TireForceSolver.relax(0,1000,10,.35,.01)
    if x<=0 or x>=1000:fail("relaxation must be progressive");return
    print("PASS: test_08_tire_relaxation")
    quit(0)
