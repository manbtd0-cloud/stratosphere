extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
	var service_script=load("res://src/world/environment/deterministic_placement_service.gd")
	if service_script==null:fail("DeterministicPlacementService script must exist");return
	var zone_script=load("res://src/world/environment/environment_zone_definition.gd");var zone=zone_script.new();zone.id=&"forest.north_hill";zone.zone_class=&"forest";zone.cell_ids.assign([&"world.proving.c-01_p02"])
	var service=service_script.new();var bounds:=AABB(Vector3(-100,0,-100),Vector3(200,0,200))
	var a:Array[Transform3D]=service.generate(zone,&"world.proving.c-01_p02",&"trees",bounds,20,8.0)
	var b:Array[Transform3D]=service.generate(zone,&"world.proving.c-01_p02",&"trees",bounds,20,8.0)
	if a.size()!=20 or b.size()!=20:fail("placement must satisfy feasible count");return
	if _fingerprint(a)!=_fingerprint(b):fail("repeat placement must be deterministic");return
	var c:Array[Transform3D]=service.generate(zone,&"world.proving.c-01_p02",&"bushes",bounds,20,8.0)
	if _fingerprint(a)==_fingerprint(c):fail("layer id must affect deterministic seed");return
	for i in a.size():
		var p:=a[i].origin
		if p.x<bounds.position.x or p.x>bounds.end.x or p.z<bounds.position.z or p.z>bounds.end.z:fail("placement escaped bounds");return
		for j in range(i):
			if p.distance_to(a[j].origin)<7.99:fail("minimum spacing violated");return
	var impossible:Array[Transform3D]=service.generate(zone,&"world.proving.c-01_p02",&"impossible",AABB(Vector3.ZERO,Vector3(1,0,1)),10,10.0)
	if not impossible.is_empty():fail("impossible request must fail closed");return
	print("PASS: phase3 02_deterministic_placement");quit(0)
func _fingerprint(values:Array[Transform3D])->String:
	var s:=""
	for t in values:
		s+="%.3f,%.3f,%.3f;"%[t.origin.x,t.origin.y,t.origin.z]
	return s.sha256_text()
