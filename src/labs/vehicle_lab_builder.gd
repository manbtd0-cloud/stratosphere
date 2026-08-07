class_name VehicleLabBuilder
extends Node3D
const ZONES=["SetupPad","AccelerationStraight","BrakingDry","BrakingWet","Skidpad30","Skidpad60","Slalom","HandlingLoop","BumpCourse","Gradient10","Gradient20","SideSlope","SurfaceGravel","SurfaceDirt","SurfaceGrass","JumpLanding","RecoveryZone","VisualStudio"]
func _ready()->void:
	for n in ZONES:
		if not has_node(n):add_child(_make_zone(n))
func _make_zone(name:String)->StaticBody3D:
	var body=StaticBody3D.new();body.name=name
	var size=Vector3(30,0.2,30);var pos=Vector3.ZERO;var surface:StringName=&"asphalt_dry";var rot=Vector3.ZERO
	match name:
		"SetupPad":pos=Vector3(0,0,0);size=Vector3(25,.2,25)
		"AccelerationStraight":pos=Vector3(0,0,-500);size=Vector3(18,.2,1000)
		"BrakingDry":pos=Vector3(-18,0,-260);size=Vector3(12,.2,420)
		"BrakingWet":pos=Vector3(18,0,-260);size=Vector3(12,.2,420);surface=&"asphalt_wet"
		"Skidpad30":pos=Vector3(-90,0,-50);size=Vector3(70,.2,70)
		"Skidpad60":pos=Vector3(-180,0,-50);size=Vector3(130,.2,130)
		"Slalom":pos=Vector3(70,0,-150);size=Vector3(30,.2,250)
		"HandlingLoop":pos=Vector3(180,0,-180);size=Vector3(180,.2,260)
		"BumpCourse":pos=Vector3(70,0,90);size=Vector3(25,.2,150)
		"Gradient10":pos=Vector3(-60,3,95);size=Vector3(18,.2,70);rot.x=deg_to_rad(-5.71)
		"Gradient20":pos=Vector3(-90,6,95);size=Vector3(18,.2,70);rot.x=deg_to_rad(-11.31)
		"SideSlope":pos=Vector3(-125,3,95);size=Vector3(30,.2,70);rot.z=deg_to_rad(8.0)
		"SurfaceGravel":pos=Vector3(120,0,80);size=Vector3(18,.2,100);surface=&"gravel"
		"SurfaceDirt":pos=Vector3(142,0,80);size=Vector3(18,.2,100);surface=&"dirt"
		"SurfaceGrass":pos=Vector3(164,0,80);size=Vector3(18,.2,100);surface=&"grass"
		"JumpLanding":pos=Vector3(0,0,130);size=Vector3(20,.2,80)
		"RecoveryZone":pos=Vector3(40,0,160);size=Vector3(40,.2,40)
		"VisualStudio":pos=Vector3(-40,0,160);size=Vector3(35,.2,35)
	body.position=pos;body.rotation=rot;body.set_meta("surface_id",surface)
	var cs=CollisionShape3D.new();var box=BoxShape3D.new();box.size=size;cs.shape=box;body.add_child(cs)
	var mi=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=size;mi.mesh=mesh;body.add_child(mi)
	return body
