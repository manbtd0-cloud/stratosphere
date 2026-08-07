extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=TireConfig.new()
    var peak=TireForceSolver.normalized_curve(c.peak_slip_ratio,c.peak_slip_ratio,c.post_peak_factor)
    var post=TireForceSolver.normalized_curve(c.peak_slip_ratio*3,c.peak_slip_ratio,c.post_peak_factor)
    if peak<.99 or post>=peak:fail("tire peak/falloff");return
    print("PASS: test_05_tire_peak")
    quit(0)
