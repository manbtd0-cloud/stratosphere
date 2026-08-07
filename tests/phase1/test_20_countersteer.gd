extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=AssistConfig.new();var x=AssistSolver.countersteer(0,.4,c)
    if x>=0 or absf(x)>1+c.max_countersteer:fail("countersteer");return
    print("PASS: test_20_countersteer")
    quit(0)
