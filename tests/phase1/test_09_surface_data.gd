extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var g=SurfaceConfig.for_id(&"gravel");var d=SurfaceConfig.for_id(&"dirt");var grass=SurfaceConfig.for_id(&"grass")
    if not (g.rolling_resistance_coefficient<d.rolling_resistance_coefficient and d.rolling_resistance_coefficient<grass.rolling_resistance_coefficient):fail("loose rolling resistance");return
    print("PASS: test_09_surface_data")
    quit(0)
