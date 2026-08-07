extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
	var script=load("res://src/labs/vehicle_lab_builder.gd")
	var lab=Node3D.new();lab.set_script(script);root.add_child(lab);await process_frame
	var world=lab.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var sun=lab.get_node_or_null("Sun") as DirectionalLight3D
	if world==null or world.environment==null:fail("lab needs deterministic WorldEnvironment");return
	if sun==null or not sun.shadow_enabled:fail("lab needs shadow-casting sun");return
	for requirement in [["BrakingDry", &"asphalt_dry"], ["BrakingWet", &"asphalt_wet"], ["SurfaceGravel", &"gravel"], ["SurfaceDirt", &"dirt"], ["SurfaceGrass", &"grass"]]:
		var zone=lab.get_node(requirement[0]) as StaticBody3D
		if StringName(zone.get_meta("surface_id")) != requirement[1]:fail("visual polish must preserve physics surface ID for %s"%requirement[0]);return
		if zone.get_node_or_null("CollisionShape3D")==null:fail("visual polish must preserve collision for %s"%requirement[0]);return
	var dry=lab.get_node("BrakingDry/MeshInstance3D") as MeshInstance3D
	var wet=lab.get_node("BrakingWet/MeshInstance3D") as MeshInstance3D
	var gravel=lab.get_node("SurfaceGravel/MeshInstance3D") as MeshInstance3D
	var dirt=lab.get_node("SurfaceDirt/MeshInstance3D") as MeshInstance3D
	var grass=lab.get_node("SurfaceGrass/MeshInstance3D") as MeshInstance3D
	for mesh in [dry,wet,gravel,dirt,grass]:
		if not mesh.material_override is StandardMaterial3D:fail("every measurement surface needs explicit material");return
	if (wet.material_override as StandardMaterial3D).roughness >= (dry.material_override as StandardMaterial3D).roughness:fail("wet asphalt must visually read wetter than dry asphalt");return
	if (gravel.material_override as StandardMaterial3D).albedo_color == (dirt.material_override as StandardMaterial3D).albedo_color:fail("gravel and dirt need distinct visual identity");return
	if (grass.material_override as StandardMaterial3D).albedo_color == (gravel.material_override as StandardMaterial3D).albedo_color:fail("grass must visually differ from loose mineral surfaces");return
	var markers=lab.get_node_or_null("MeasurementMarkers")
	if markers==null or markers.get_child_count()<12:fail("lab needs deterministic distance/slalom markers");return
	var studio=lab.get_node("VisualStudio")
	if studio.get_node_or_null("StudioBackdrop")==null:fail("visual studio needs backdrop");return
	if studio.get_node_or_null("StudioKeyLight")==null or studio.get_node_or_null("StudioFillLight")==null:fail("visual studio needs key/fill lighting");return
	lab.queue_free();await process_frame
	print("PASS: phase1 47_lab_presentation")
	quit(0)
