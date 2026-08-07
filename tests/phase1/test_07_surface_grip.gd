extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=TireConfig.new();var dry=TireForceSolver.calculate(c,3000,.11,0,SurfaceConfig.for_id(&"asphalt_dry"));var wet=TireForceSolver.calculate(c,3000,.11,0,SurfaceConfig.for_id(&"asphalt_wet"));var gravel=TireForceSolver.calculate(c,3000,.11,0,SurfaceConfig.for_id(&"gravel"))
    if absf(dry.longitudinal)<=absf(wet.longitudinal) or absf(wet.longitudinal)<=absf(gravel.longitudinal):fail("surface grip order");return
    print("PASS: test_07_surface_grip")
    quit(0)
