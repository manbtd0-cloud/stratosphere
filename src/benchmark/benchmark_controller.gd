class_name BenchmarkController
extends Node


signal benchmark_completed(report: Dictionary)

@export var workload_id: StringName = &"graphics_lab"
@export var quality_profile: StringName = &"medium"

var _running := false
var _duration_target := 0.0
var _elapsed := 0.0
var _frame_times := PackedFloat64Array()


func begin_run(duration_seconds: float) -> void:
	_duration_target = maxf(duration_seconds, 0.05)
	_elapsed = 0.0
	_frame_times = PackedFloat64Array()
	_running = true
	set_process(true)


func _process(delta: float) -> void:
	if not _running:
		return
	var safe_delta := maxf(delta, 0.000001)
	_elapsed += safe_delta
	_frame_times.append(safe_delta)
	if _elapsed < _duration_target:
		return
	_running = false
	set_process(false)
	var authoritative := DisplayServer.get_name() != "headless" and not RenderingServer.get_video_adapter_name().is_empty()
	var report := build_report(_frame_times, _elapsed, quality_profile, authoritative)
	benchmark_completed.emit(report)


func build_report(
	frame_times: PackedFloat64Array,
	duration_seconds: float,
	profile_id: StringName,
	authoritative_hardware: bool
) -> Dictionary:
	var frame_count := frame_times.size()
	var maximum_delta := 0.0
	for sample in frame_times:
		maximum_delta = maxf(maximum_delta, sample)
	var safe_duration := maxf(duration_seconds, 0.000001)
	var average_fps := float(frame_count) / safe_duration
	var minimum_fps := 0.0 if maximum_delta <= 0.0 else 1.0 / maximum_delta
	var resolution := Vector2i.ZERO
	if is_inside_tree() and get_viewport() != null:
		resolution = Vector2i(get_viewport().get_visible_rect().size)
	var version_info := Engine.get_version_info()
	return {
		"engine_version": str(version_info.get("string", "unknown")),
		"operating_system": OS.get_name(),
		"processor": OS.get_processor_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"rendering_driver": RenderingServer.get_current_rendering_driver_name(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"authoritative_hardware": authoritative_hardware,
		"quality_profile": String(profile_id),
		"workload": String(workload_id),
		"resolution": {"width": resolution.x, "height": resolution.y},
		"average_fps": average_fps,
		"minimum_fps": minimum_fps,
		"maximum_frame_ms": maximum_delta * 1000.0,
		"frame_count": frame_count,
		"duration_seconds": duration_seconds,
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"rendered_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"rendered_primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"video_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"pipeline_compilations_mesh": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH)),
		"pipeline_compilations_surface": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE)),
		"pipeline_compilations_draw": int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW)),
	}


func write_report(path: String, report: Dictionary) -> Error:
	var absolute_parent := ProjectSettings.globalize_path(path.get_base_dir())
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_parent)
	if make_error != OK and make_error != ERR_ALREADY_EXISTS:
		return make_error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(report, "\t"))
	file.flush()
	file.close()
	return OK
