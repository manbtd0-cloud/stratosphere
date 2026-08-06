class_name GraphicsLabBuilder
extends Node3D


@export_enum("graphics_lab", "open_world_proxy", "pipeline_warmup") var workload := "graphics_lab"


func _ready() -> void:
	_build_environment()
	match workload:
		"open_world_proxy":
			_build_open_world_proxy()
		"pipeline_warmup":
			_build_pipeline_warmup()
		_:
			_build_graphics_lab()


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.08, 0.11, 0.16)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.38, 0.45, 0.58)
	environment.ambient_light_energy = 0.55
	environment.glow_enabled = true
	environment.ssao_enabled = true
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)

	var camera := Camera3D.new()
	camera.name = "BenchmarkCamera"
	camera.position = Vector3(0.0, 5.0, 13.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 1.0, 0.0))
	camera.current = true
	add_child(camera)


func _build_graphics_lab() -> void:
	_add_box(Vector3(0.0, -0.3, 0.0), Vector3(22.0, 0.5, 18.0), Color(0.08, 0.09, 0.1), 0.25, 0.0)
	for row in range(4):
		for column in range(6):
			var roughness := float(column) / 5.0
			var metallic := float(row) / 3.0
			var hue := float(row * 6 + column) / 24.0
			_add_sphere(
				Vector3(-6.25 + column * 2.5, 1.0 + row * 2.0, 0.0),
				Color.from_hsv(hue, 0.55, 0.85),
				roughness,
				metallic
			)
	_add_box(Vector3(0.0, 1.0, -5.5), Vector3(5.0, 1.2, 2.2), Color(0.2, 0.02, 0.025), 0.12, 0.85)


func _build_open_world_proxy() -> void:
	_add_box(Vector3(0.0, -0.35, -20.0), Vector3(18.0, 0.5, 100.0), Color(0.12, 0.13, 0.14), 0.72, 0.0)
	for index in range(180):
		var side := -1.0 if index % 2 == 0 else 1.0
		var lane_index := index / 2
		var z := -5.0 - float(lane_index) * 2.2
		var x := side * (7.0 + float((index * 17) % 9))
		var height := 1.5 + float((index * 13) % 20) * 0.12
		_add_tree_proxy(Vector3(x, height * 0.5, z), height)
	for index in range(40):
		var x := -28.0 + float((index * 19) % 56)
		var z := -10.0 - float(index) * 5.0
		_add_box(Vector3(x, 1.0, z), Vector3(2.0, 2.0, 2.0), Color(0.18, 0.16, 0.14), 0.8, 0.0)


func _build_pipeline_warmup() -> void:
	for index in range(32):
		var metallic := 1.0 if index % 3 == 0 else 0.0
		var roughness := 0.08 + float(index % 8) * 0.11
		var color := Color.from_hsv(float(index) / 32.0, 0.65, 0.9)
		_add_sphere(Vector3(-7.0 + float(index % 8) * 2.0, 1.0 + float(index / 8) * 2.0, 0.0), color, roughness, metallic)


func _add_sphere(position_value: Vector3, color: Color, roughness: float, metallic: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.72
	sphere.height = 1.44
	mesh_instance.mesh = sphere
	mesh_instance.position = position_value
	mesh_instance.material_override = _make_material(color, roughness, metallic)
	add_child(mesh_instance)


func _add_box(position_value: Vector3, size: Vector3, color: Color, roughness: float, metallic: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = position_value
	mesh_instance.material_override = _make_material(color, roughness, metallic)
	add_child(mesh_instance)


func _add_tree_proxy(position_value: Vector3, height: float) -> void:
	var trunk := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.12
	cylinder.bottom_radius = 0.18
	cylinder.height = height
	trunk.mesh = cylinder
	trunk.position = position_value
	trunk.material_override = _make_material(Color(0.16, 0.09, 0.045), 0.9, 0.0)
	add_child(trunk)
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = height * 0.42
	sphere.height = height * 0.84
	crown.mesh = sphere
	crown.position = position_value + Vector3(0.0, height * 0.55, 0.0)
	crown.material_override = _make_material(Color(0.07, 0.22, 0.09), 0.92, 0.0)
	add_child(crown)


func _make_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = clampf(roughness, 0.0, 1.0)
	material.metallic = clampf(metallic, 0.0, 1.0)
	return material
