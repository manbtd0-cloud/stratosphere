extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=AssistConfig.new();var f=AssistSolver.tcs_factor(1,.5,c,.1)
    if f>=1 or f<=0:fail("TCS modulation");return
    print("PASS: test_18_tcs")
    quit(0)
