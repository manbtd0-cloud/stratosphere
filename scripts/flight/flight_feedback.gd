class_name FlightFeedback
extends Node3D

@export var left_exhaust_path: NodePath = NodePath("LeftExhaust")
@export var right_exhaust_path: NodePath = NodePath("RightExhaust")
@export var engine_audio_path: NodePath = NodePath("EngineAudio")
@export var wind_audio_path: NodePath = NodePath("WindAudio")

var _engine_intensity: float = 0.0
var _wind_intensity: float = 0.0
var _engine_phase: float = 0.0
var _wind_phase: float = 0.0
var _noise_state: int = 0x13579BDF
var _left_exhaust: MeshInstance3D
var _right_exhaust: MeshInstance3D
var _engine_audio: AudioStreamPlayer3D
var _wind_audio: AudioStreamPlayer3D
var _engine_playback: AudioStreamGeneratorPlayback
var _wind_playback: AudioStreamGeneratorPlayback
var _connected_craft: FrontierVtolController


static func calculate_engine_intensity(
	collective: float,
	transition: float,
	thrust_newtons: float
) -> float:
	var normalized_thrust := clampf(thrust_newtons / 72000.0, 0.0, 1.0)
	return clampf(
		clampf(collective, 0.0, 1.0) * 0.7
		+ clampf(transition, 0.0, 1.0) * 0.15
		+ normalized_thrust * 0.15,
		0.0,
		1.0
	)


static func calculate_wind_intensity(speed_mps: float) -> float:
	return smoothstep(15.0, 220.0, maxf(speed_mps, 0.0))


static func calculate_exhaust_length(engine_intensity: float) -> float:
	return lerpf(0.35, 3.2, clampf(engine_intensity, 0.0, 1.0))


func _ready() -> void:
	_left_exhaust = get_node_or_null(left_exhaust_path) as MeshInstance3D
	_right_exhaust = get_node_or_null(right_exhaust_path) as MeshInstance3D
	_engine_audio = get_node_or_null(engine_audio_path) as AudioStreamPlayer3D
	_wind_audio = get_node_or_null(wind_audio_path) as AudioStreamPlayer3D

	_connected_craft = get_parent() as FrontierVtolController
	if (
		_connected_craft != null
		and not _connected_craft.telemetry_updated.is_connected(update_from_telemetry)
	):
		_connected_craft.telemetry_updated.connect(update_from_telemetry)

	_start_generator(_engine_audio)
	_start_generator(_wind_audio)
	_refresh_exhausts()


func _exit_tree() -> void:
	if (
		is_instance_valid(_connected_craft)
		and _connected_craft.telemetry_updated.is_connected(update_from_telemetry)
	):
		_connected_craft.telemetry_updated.disconnect(update_from_telemetry)

	shutdown_audio()
	_engine_audio = null
	_wind_audio = null
	_left_exhaust = null
	_right_exhaust = null
	_connected_craft = null


func _process(_delta: float) -> void:
	_fill_engine_audio()
	_fill_wind_audio()


func update_from_telemetry(telemetry: Dictionary) -> void:
	_engine_intensity = calculate_engine_intensity(
		float(telemetry.get("collective", 0.0)),
		float(telemetry.get("transition", 0.0)),
		float(telemetry.get("thrust_newtons", 0.0))
	)
	_wind_intensity = calculate_wind_intensity(
		float(telemetry.get("speed_mps", 0.0))
	)
	_refresh_exhausts()
	if _engine_audio != null:
		_engine_audio.volume_db = lerpf(-32.0, -5.0, _engine_intensity)
		_engine_audio.pitch_scale = lerpf(0.72, 1.35, _engine_intensity)
	if _wind_audio != null:
		_wind_audio.volume_db = lerpf(-48.0, -8.0, _wind_intensity)


func has_active_audio_playback() -> bool:
	return (
		_engine_playback != null
		or _wind_playback != null
		or (is_instance_valid(_engine_audio) and _engine_audio.playing)
		or (is_instance_valid(_wind_audio) and _wind_audio.playing)
	)


func shutdown_audio() -> void:
	if is_instance_valid(_engine_audio):
		_engine_audio.stop()
		_engine_audio.stream = null
	if is_instance_valid(_wind_audio):
		_wind_audio.stop()
		_wind_audio.stream = null
	_engine_playback = null
	_wind_playback = null


func _start_generator(player: AudioStreamPlayer3D) -> void:
	if player == null or not player.stream is AudioStreamGenerator:
		return
	if not player.playing:
		player.play()
	var playback := player.get_stream_playback()
	if player == _engine_audio:
		_engine_playback = playback as AudioStreamGeneratorPlayback
	elif player == _wind_audio:
		_wind_playback = playback as AudioStreamGeneratorPlayback


func _refresh_exhausts() -> void:
	var length := calculate_exhaust_length(_engine_intensity)
	for exhaust in [_left_exhaust, _right_exhaust]:
		if exhaust == null:
			continue
		exhaust.scale = Vector3(1.0, length, 1.0)
		exhaust.visible = _engine_intensity > 0.01


func _fill_engine_audio() -> void:
	if _engine_playback == null or _engine_audio == null:
		return
	var generator := _engine_audio.stream as AudioStreamGenerator
	if generator == null:
		return
	var sample_rate := generator.mix_rate
	var available := mini(_engine_playback.get_frames_available(), 1024)
	var base_frequency := lerpf(46.0, 92.0, _engine_intensity)
	for _index in range(available):
		_engine_phase = fmod(_engine_phase + base_frequency / sample_rate, 1.0)
		var fundamental := sin(TAU * _engine_phase)
		var harmonic := sin(TAU * _engine_phase * 2.0) * 0.32
		var sample := (fundamental + harmonic) * lerpf(0.015, 0.16, _engine_intensity)
		_engine_playback.push_frame(Vector2(sample, sample))


func _fill_wind_audio() -> void:
	if _wind_playback == null or _wind_audio == null:
		return
	var available := mini(_wind_playback.get_frames_available(), 1024)
	for _index in range(available):
		_noise_state = (_noise_state * 1103515245 + 12345) & 0x7FFFFFFF
		var white_noise := float(_noise_state) / float(0x7FFFFFFF) * 2.0 - 1.0
		_wind_phase = lerpf(_wind_phase, white_noise, 0.08)
		var sample := _wind_phase * _wind_intensity * 0.12
		_wind_playback.push_frame(Vector2(sample, sample))