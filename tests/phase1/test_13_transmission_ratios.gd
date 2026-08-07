extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=TransmissionConfig.new()
    if TransmissionSolver.ratio(c,1)<=TransmissionSolver.ratio(c,2) or TransmissionSolver.ratio(c,-1)>=0 or TransmissionSolver.ratio(c,0)!=0:fail("ratios");return
    print("PASS: test_13_transmission_ratios")
    quit(0)
