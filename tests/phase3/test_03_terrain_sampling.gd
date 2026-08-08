extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
	var backend_script=load("res://src/world/terrain/builtin_terrain_backend.gd")
	if backend_script==null:fail("BuiltinTerrainBackend must load");return
	var backend=backend_script.new()
	if not backend.has_method("sample_height") or not backend.has_method("sample_normal"):fail("terrain backend must expose sample_height/sample_normal");return
	var highway:=Vector3(0,0,500);var country:=Vector3(500,0,50);var hill:=Vector3(-350,0,-850);var dirt:=Vector3(300,0,-100)
	var h0:float=backend.sample_height(highway);var hc:float=backend.sample_height(country);var hh:float=backend.sample_height(hill);var hd:float=backend.sample_height(dirt)
	if not is_equal_approx(h0,backend.sample_height(highway)):fail("terrain height must be deterministic");return
	if hh-h0<40.0:fail("hill terrain must rise meaningfully above highway: %.2f vs %.2f"%[hh,h0]);return
	if absf(hc)>60.0 or absf(hd)>60.0:fail("countryside/dirt macro terrain exceeded sane range");return
	for p in [highway,country,hill,dirt]:
		var n:Vector3=backend.sample_normal(p)
		if absf(n.length()-1.0)>0.001 or n.y<0.2:fail("terrain normal must be normalized/upward: %s"%n);return
	print("PASS: phase3 03_terrain_sampling");quit(0)
