extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=EngineConfig.new()
    if EngineSolver.requested_torque(c,3000,0)>=0 or EngineSolver.requested_torque(c,c.limiter_rpm,1)!=0:fail("engine braking/limiter");return
    print("PASS: test_11_engine_braking")
    quit(0)
