class_name FlightFeedback
extends Node3D

const AUDIO_SAMPLE_RATE: int = 22050
const AUDIO_FRAME_COUNT: int = AUDIO_SAMPLE_RATE
const ENGINE_BASE_FREQUENCY_HZ: float = 55.0
const PCM_MAXIMUM: float = 32767.0

@export var left_exhaust_path: NodePath = NodePath("LeftExhaust")
@export var right_exhaust_path: NodePath = NodePath("RightExhaust")
@export var engine_audio_path: NodePath = NodePath("EngineAudio")
@export var wind_audio_path: NodePath = NodePath("WindAudio")

var _engine_intensity: float = 0.0
var _wind_intensity: float = 0.0
var _left_exhaust: MeshInstance3D
var _right_exhaust: MeshInstance3D
var _engine_audio: AudioStreamPlayer3D
var _wind_audio: AudioStreamPlayer3D
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

	_start_loop(_engine_audio, _create_engine_stream())
	_start_loop(_wind_audio, _create_wind_stream())
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
		_wind_audio.pitch_scale = lerpf(0.72, 1.18, _wind_intensity)


func has_active_audio_playback() -> bool:
	return (
		is_instance_valid(_engine_audio)
		and (_engine_audio.playing or _engine_audio.stream != null)
	) or (
		is_instance_valid(_wind_audio)
		and (_wind_audio.playing or _wind_audio.stream != null)
	)


func shutdown_audio() -> void:
	if is_instance_valid(_engine_audio):
		_engine_audio.stop()
		_engine_audio.stream = null
	if is_instance_valid(_wind_audio):
		_wind_audio.stop()
		_wind_audio.stream = null


func _start_loop(player: AudioStreamPlayer3D, stream: AudioStreamWAV) -> void:
	if player == null or stream == null:
		return
	player.stream = stream
	player.play()


func _create_engine_stream() -> AudioStreamWAV:
	var samples := PackedByteArray()
	samples.resize(AUDIO_FRAME_COUNT * 4)

	for frame in range(AUDIO_FRAME_COUNT):
		var time_seconds := float(frame) / float(AUDIO_SAMPLE_RATE)
		var fundamental := sin(TAU * ENGINE_BASE_FREQUENCY_HZ * time_seconds)
		var second_harmonic := sin(
			TAU * ENGINE_BASE_FREQUENCY_HZ * 2.0 * time_seconds
		) * 0.32
		var third_harmonic := sin(
			TAU * ENGINE_BASE_FREQUENCY_HZ * 3.0 * time_seconds
		) * 0.12
		var normalized_sample := (fundamental + second_harmonic + third_harmonic) * 0.23
		_write_stereo_sample(samples, frame, normalized_sample)

	return _build_looping_stream(samples)


func _create_wind_stream() -> AudioStreamWAV:
	var samples := PackedByteArray()
	samples.resize(AUDIO_FRAME_COUNT * 4)
	var noise_state: int = 0x13579BDF
	var filtered_noise: float = 0.0

	for frame in range(AUDIO_FRAME_COUNT):
		noise_state = (noise_state * 1103515245 + 12345) & 0x7FFFFFFF
		var white_noise := float(noise_state) / float(0x7FFFFFFF) * 2.0 - 1.0
		filtered_noise = lerpf(filtered_noise, white_noise, 0.075)
		_write_stereo_sample(samples, frame, filtered_noise * 0.34)

	return _build_looping_stream(samples)


func _build_looping_stream(samples: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = AUDIO_SAMPLE_RATE
	stream.stereo = true
	stream.data = samples
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = AUDIO_FRAME_COUNT
	return stream


func _write_stereo_sample(
	samples: PackedByteArray,
	frame: int,
	normalized_sample: float
) -> void:
	var pcm_sample := clampi(
		roundi(clampf(normalized_sample, -1.0, 1.0) * PCM_MAXIMUM),
		-32768,
		32767
	)
	var byte_offset := frame * 4
	samples.encode_s16(byte_offset, pcm_sample)
	samples.encode_s16(byte_offset + 2, pcm_sample)


func _refresh_exhausts() -> void:
	var length := calculate_exhaust_length(_engine_intensity)
	for exhaust in [_left_exhaust, _right_exhaust]:
		if exhaust == null:
			continue
		exhaust.scale = Vector3(1.0, length, 1.0)
		exhaust.visible = _engine_intensity > 0.01