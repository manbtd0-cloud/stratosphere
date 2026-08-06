extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var scenes := PackedStringArray([
		"res://src/benchmark/graphics_lab.tscn",
		"res://src/benchmark/open_world_proxy.tscn",
		"res://src/benchmark/pipeline_warmup.tscn",
	])
	for scene_path in scenes:
		var packed = load(scene_path)
		if packed == null or not packed is PackedScene:
			fail("benchmark scene must load: %s" % scene_path)
			return
		var instance = packed.instantiate()
		var controller = instance.get_node_or_null("BenchmarkController")
		if controller == null:
			fail("benchmark scene must contain BenchmarkController: %s" % scene_path)
			return
		instance.free()
	print("PASS: benchmark scene contract")
	quit(0)
