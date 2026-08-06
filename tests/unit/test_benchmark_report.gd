extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var controller_script := load("res://src/benchmark/benchmark_controller.gd")
	if controller_script == null:
		fail("benchmark controller must load")
		return
	var controller = controller_script.new()
	controller.workload_id = &"unit"
	var samples := PackedFloat64Array([0.016, 0.020, 0.018])
	var report: Dictionary = controller.build_report(samples, 0.054, &"medium", false)
	var required := PackedStringArray([
		"engine_version", "operating_system", "processor", "renderer", "rendering_driver",
		"video_adapter", "authoritative_hardware", "quality_profile", "workload",
		"resolution", "average_fps", "minimum_fps", "maximum_frame_ms", "frame_count",
		"duration_seconds", "draw_calls", "rendered_objects", "rendered_primitives",
		"video_memory_bytes", "pipeline_compilations_mesh", "pipeline_compilations_surface",
		"pipeline_compilations_draw"
	])
	for key in required:
		if not report.has(key):
			fail("benchmark report missing key: %s" % key)
			return
	if report.frame_count != 3:
		fail("benchmark frame count must match samples")
		return
	if not is_equal_approx(report.maximum_frame_ms, 20.0):
		fail("maximum frame time must be 20 ms")
		return
	if report.authoritative_hardware:
		fail("unit report must preserve non-authoritative flag")
		return
	var output := "user://phase0-tests/benchmark-report.json"
	if controller.write_report(output, report) != OK or not FileAccess.file_exists(output):
		fail("benchmark report must write to JSON")
		return
	controller.free()
	print("PASS: benchmark report contract")
	quit(0)
