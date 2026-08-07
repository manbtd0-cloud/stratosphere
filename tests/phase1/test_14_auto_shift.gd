extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=TransmissionConfig.new()
    if TransmissionSolver.automatic_gear(c,1,7000,1)!=2 or TransmissionSolver.automatic_gear(c,2,2000,.5)!=1:fail("shift hysteresis");return
    print("PASS: test_14_auto_shift")
    quit(0)
