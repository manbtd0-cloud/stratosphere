extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=TireConfig.new();var s=SurfaceConfig.for_id(&"asphalt_dry");var f=TireForceSolver.calculate(c,3000,.2,.2,s)
    var mag=Vector2(f.longitudinal,f.lateral).length()
    if float(f.utilization)>1.0001 or mag>3600:fail("friction ellipse exceeded");return
    print("PASS: test_06_combined_slip")
    quit(0)
