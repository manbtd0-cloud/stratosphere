extends SceneTree


const DEFAULT_SCENE := "res://src/benchmark/graphics_lab.tscn"
const DEFAULT_OUTPUT := "user://reports/benchmark/latest.json"

var _scene_path := DEFAULT_SCENE
var _output_path := DEFAULT_OUTPUT
var _duration := 1.0
var _profile: StringName = &"medium"


func _init() -> void:
	_parse_arguments()
	call_deferred("_start")


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			_scene_path = argument.trim_prefix("--scene=")
		elif argument.begins_with("--output="):
			_output_path = argument.trim_prefix("--output=")
		elif argument.begins_with("--duration="):
			_duration = maxf(float(argument.trim_prefix("--duration=")), 0.05)
		elif argument.begins_with("--profile="):
			_profile = StringName(argument.trim_prefix("--profile="))


func _start() -> void:
	var packed = load(_scene_path)
	if packed == null or not packed is PackedScene:
		push_error("Unable to load benchmark scene: %s" % _scene_path)
		quit(1)
		return
	var instance = packed.instantiate()
	root.add_child(instance)
	var controller = instance.get_node_or_null("BenchmarkController")
	if controller == null:
		push_error("BenchmarkController missing from scene: %s" % _scene_path)
		quit(1)
		return
	controller.quality_profile = _profile
	controller.benchmark_completed.connect(_on_benchmark_completed.bind(controller))
	controller.begin_run(_duration)


func _on_benchmark_completed(report: Dictionary, controller: Node) -> void:
	var error: Error = controller.write_report(_output_path, report)
	if error != OK:
		push_error("Unable to write benchmark report: %s" % error_string(error))
		quit(1)
		return
	print(JSON.stringify(report))
	quit(0)
