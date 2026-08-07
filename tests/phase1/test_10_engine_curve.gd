extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=EngineConfig.new()
    if EngineSolver.torque_at(c,4800)<195 or EngineSolver.torque_at(c,850)<=0:fail("torque curve");return
    print("PASS: test_10_engine_curve")
    quit(0)
