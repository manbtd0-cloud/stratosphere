extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/flight_room/flight_room.tscn"
const PHYSICS_FRAMES_TO_RUN := 240


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

	root.remove_child(gameplay_scene)
	gameplay_scene.free()

	# Allow queued signal disconnections, audio shutdown, and rendering cleanup
	# to complete before the SceneTree exits.
	await process_frame
	await process_frame
	await physics_frame

	print("PASS: gameplay scene smoke test")
	quit(0)