extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=AssistConfig.new();var x=AssistSolver.stability(1,0,c)
    if x.torque_cut>c.max_stability_torque_cut or maxf(x.brake_left,x.brake_right)>c.max_stability_brake:fail("stability bounds");return
    print("PASS: test_19_stability")
    quit(0)
