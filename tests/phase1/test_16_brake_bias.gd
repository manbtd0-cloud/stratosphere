extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=BrakeConfig.new()
    if BrakeSolver.axle_torque(c,1,true)<=BrakeSolver.axle_torque(c,1,false):fail("front bias");return
    print("PASS: test_16_brake_bias")
    quit(0)
