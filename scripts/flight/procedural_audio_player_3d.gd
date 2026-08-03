class_name ProceduralAudioPlayer3D
extends AudioStreamPlayer3D


func _ready() -> void:
	if not tree_exiting.is_connected(shutdown_audio):
		tree_exiting.connect(shutdown_audio)


func shutdown_audio() -> void:
	stop()
	stream = null