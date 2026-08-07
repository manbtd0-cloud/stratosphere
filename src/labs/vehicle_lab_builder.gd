class_name VehicleLabBuilder
extends Node3D

const ZONES = ["SetupPad","AccelerationStraight","BrakingDry","BrakingWet","Skidpad30","Skidpad60","Slalom","HandlingLoop","BumpCourse","Gradient10","Gradient20","SideSlope","SurfaceGravel","SurfaceDirt","SurfaceGrass","JumpLanding","RecoveryZone","VisualStudio"]

var _surface_materials: Dictionary = {}
var _marker_material: StandardMaterial3D
var _cone_material: StandardMaterial3D

func _ready() -> void:
	_build_materials()
	_build_environment()
	for zone_name in ZONES:
		if not has_node(zone_name):
			add_child(_make_zone(zone_name))
	_build_measurement_markers()

func _build_materials() -> void:
	_surface_materials = {
		&"asphalt_dry": _material(Color(0.115, 0.125, 0.135), 0.82),
		&"asphalt_wet": _material(Color(0.045, 0.055, 0.065), 0.16, 0.05),
		&"gravel": _material(Color(0.34, 0.31, 0.26), 0.94),
		&"dirt": _material(Color(0.27, 0.15, 0.08), 0.97),
		&"grass": _material(Color(0.075, 0.20, 0.07), 0.98),
	}
	_marker_material = _material(Color(0.92, 0.93, 0.88), 0.48)
	_marker_material.emission_enabled = true
	_marker_material.emission = Color(0.16, 0.16, 0.13)
	_cone_material = _material(Color(0.95, 0.24, 0.035), 0.58)

func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _build_environment() -> void:
	if not has_node("WorldEnvironment"):
		var world := WorldEnvironment.new()
		world.name = "WorldEnvironment"
		var environment := Environment.new()
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.33, 0.46, 0.62)
		environment.background_energy_multiplier = 0.8
		environment.ambient_light_color = Color(0.56, 0.62, 0.70)
		environment.ambient_light_energy = 0.58
		environment.tonemap_mode = Environment.TONE_MAPPER_ACES
		world.environment = environment
		add_child(world)
	if not has_node("Sun"):
		var sun := DirectionalLight3D.new()
		sun.name = "Sun"
		sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
		sun.light_color = Color(1.0, 0.91, 0.80)
		sun.light_energy = 1.15
		sun.shadow_enabled = true
		sun.directional_shadow_max_distance = 450.0
		add_child(sun)

func _make_zone(name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	var size := Vector3(30, 0.2, 30)
	var pos := Vector3.ZERO
	var surface: StringName = &"asphalt_dry"
	var rot := Vector3.ZERO
	match name:
		"SetupPad": pos = Vector3(0,0,0); size = Vector3(25,.2,25)
		"AccelerationStraight": pos = Vector3(0,0,-500); size = Vector3(18,.2,1000)
		"BrakingDry": pos = Vector3(-18,0,-260); size = Vector3(12,.2,420)
		"BrakingWet": pos = Vector3(18,0,-260); size = Vector3(12,.2,420); surface = &"asphalt_wet"
		"Skidpad30": pos = Vector3(-90,0,-50); size = Vector3(70,.2,70)
		"Skidpad60": pos = Vector3(-180,0,-50); size = Vector3(130,.2,130)
		"Slalom": pos = Vector3(70,0,-150); size = Vector3(30,.2,250)
		"HandlingLoop": pos = Vector3(180,0,-180); size = Vector3(180,.2,260)
		"BumpCourse": pos = Vector3(70,0,90); size = Vector3(25,.2,150)
		"Gradient10": pos = Vector3(-60,3,95); size = Vector3(18,.2,70); rot.x = deg_to_rad(-5.71)
		"Gradient20": pos = Vector3(-90,6,95); size = Vector3(18,.2,70); rot.x = deg_to_rad(-11.31)
		"SideSlope": pos = Vector3(-125,3,95); size = Vector3(30,.2,70); rot.z = deg_to_rad(8.0)
		"SurfaceGravel": pos = Vector3(120,0,80); size = Vector3(18,.2,100); surface = &"gravel"
		"SurfaceDirt": pos = Vector3(142,0,80); size = Vector3(18,.2,100); surface = &"dirt"
		"SurfaceGrass": pos = Vector3(164,0,80); size = Vector3(18,.2,100); surface = &"grass"
		"JumpLanding": pos = Vector3(0,0,130); size = Vector3(20,.2,80)
		"RecoveryZone": pos = Vector3(40,0,160); size = Vector3(40,.2,40)
		"VisualStudio": pos = Vector3(-40,0,160); size = Vector3(35,.2,35)
	body.position = pos
	body.rotation = rot
	body.set_meta("surface_id", surface)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var visual := MeshInstance3D.new()
	visual.name = "MeshInstance3D"
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = _surface_materials.get(surface, _surface_materials[&"asphalt_dry"])
	body.add_child(visual)
	if name == "VisualStudio":
		_decorate_visual_studio(body)
	return body

func _build_measurement_markers() -> void:
	if has_node("MeasurementMarkers"):
		return
	var root := Node3D.new()
	root.name = "MeasurementMarkers"
	add_child(root)
	for index in range(1, 10):
		root.add_child(_marker_strip("Straight%03dm" % (index * 100), Vector3(0, 0.13, -index * 100.0), Vector3(17.2, 0.025, 0.16)))
	for index in range(5):
		root.add_child(_marker_strip("DryBrake%02d" % index, Vector3(-18, 0.13, -120.0 - index * 60.0), Vector3(11.2, 0.025, 0.14)))
	for index in range(5):
		root.add_child(_marker_strip("WetBrake%02d" % index, Vector3(18, 0.13, -120.0 - index * 60.0), Vector3(11.2, 0.025, 0.14)))
	for index in range(10):
		var side := -1.0 if index % 2 == 0 else 1.0
		root.add_child(_cone("SlalomCone%02d" % index, Vector3(70.0 + side * 3.2, 0.36, -45.0 - index * 22.0)))

func _marker_strip(name: String, position: Vector3, size: Vector3) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	marker.name = name
	marker.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	marker.mesh = mesh
	marker.material_override = _marker_material
	return marker

func _cone(name: String, position: Vector3) -> MeshInstance3D:
	var cone := MeshInstance3D.new()
	cone.name = name
	cone.position = position
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.04
	mesh.bottom_radius = 0.22
	mesh.height = 0.62
	mesh.radial_segments = 12
	cone.mesh = mesh
	cone.material_override = _cone_material
	return cone

func _decorate_visual_studio(studio: StaticBody3D) -> void:
	var backdrop := MeshInstance3D.new()
	backdrop.name = "StudioBackdrop"
	backdrop.position = Vector3(0, 4.0, 11.0)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(30, 8, 0.3)
	backdrop.mesh = mesh
	backdrop.material_override = _material(Color(0.065, 0.07, 0.08), 0.72)
	studio.add_child(backdrop)
	var key := OmniLight3D.new()
	key.name = "StudioKeyLight"
	key.position = Vector3(-6, 5.5, -3)
	key.light_color = Color(1.0, 0.84, 0.70)
	key.light_energy = 8.0
	key.omni_range = 18.0
	key.shadow_enabled = true
	studio.add_child(key)
	var fill := OmniLight3D.new()
	fill.name = "StudioFillLight"
	fill.position = Vector3(6, 3.5, 1)
	fill.light_color = Color(0.55, 0.70, 1.0)
	fill.light_energy = 4.0
	fill.omni_range = 16.0
	studio.add_child(fill)
