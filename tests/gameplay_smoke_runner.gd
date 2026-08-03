extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/flight_room/flight_room.tscn"
const PHYSICS_FRAMES_TO_RUN := 240
const AUDIO_RELEASE_FRAMES := 16


func _initialize() -> void:
	call_deferred("_run_smoke_test")


func _run_smoke_test() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Unable to load gameplay scene: %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	var gameplay_scene := packed.instantiate()
	if gameplay_scene == null:
		push_error("Unable to instantiate gameplay scene: %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	root.add_child(gameplay_scene)
	for _frame in range(PHYSICS_FRAMES_TO_RUN):
		await physics_frame

	var feedback := gameplay_scene.find_child("FlightFeedback", true, false) as FlightFeedback
	if feedback == null:
		push_error("Gameplay scene is missing FlightFeedback")
		gameplay_scene.free()
		quit(1)
		return

	feedback.shutdown_audio()
	if feedback.has_active_audio_playback():
		push_error("FlightFeedback audio remained active after shutdown")
		gameplay_scene.free()
		quit(1)
		return

	# AudioServer releases playback resources asynchronously. Keep the scene
	# alive briefly after clearing both streams, then perform normal teardown.
	for _frame in range(AUDIO_RELEASE_FRAMES):
		await process_frame

	root.remove_child(gameplay_scene)
	gameplay_scene.free()

	for _frame in range(4):
		await process_frame
	await physics_frame

	print("PASS: gameplay scene smoke test")
	quit(0)