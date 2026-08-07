extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var rig := VehicleVisualRig.new()
	if rig.recommended_lod_for_distance(5.0, 0) != 0:
		fail("near vehicle must use LOD0")
		return
	if rig.recommended_lod_for_distance(20.0, 0) != 1 or rig.recommended_lod_for_distance(45.0, 1) != 2 or rig.recommended_lod_for_distance(90.0, 2) != 3:
		fail("distance policy must progress through LOD1-LOD3")
		return
	if rig.recommended_lod_for_distance(13.0, 1) != 1:
		fail("LOD hysteresis must prevent boundary flapping")
		return
	var lod0_path := rig.runtime_path(0)
	var lod3_path := rig.runtime_path(3)
	if FileAccess.file_exists(lod0_path) and FileAccess.file_exists(lod3_path):
		var stage := Node3D.new()
		root.add_child(stage)
		var camera := Camera3D.new()
		camera.current = true
		camera.position = Vector3(0, 0, 90)
		stage.add_child(camera)
		rig.lod_check_interval = 0.05
		stage.add_child(rig)
		for _i in 20:
			await process_frame
		if rig.get_active_lod() != 3:
			fail("far active camera must select runtime LOD3")
			return
		camera.position = Vector3(0, 0, 5)
		for _i in 20:
			await process_frame
		if rig.get_active_lod() != 0:
			fail("near active camera must return runtime LOD0")
			return
		stage.queue_free()
		await process_frame
	else:
		rig.free()
	print("PASS: phase1 46_auto_lod")
	quit(0)
