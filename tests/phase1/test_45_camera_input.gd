extends SceneTree

func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("run")

func add_marker(parent: Node3D, name: String, position: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = name
	marker.position = position
	parent.add_child(marker)

func run() -> void:
	var target := Node3D.new()
	target.name = "Target"
	root.add_child(target)
	var anchors := Node3D.new()
	anchors.name = "CameraAnchors"
	target.add_child(anchors)
	add_marker(anchors, "ChaseAnchor", Vector3(0, 2, 6))
	add_marker(anchors, "HoodAnchor", Vector3(0, 1, -1))
	add_marker(anchors, "BumperAnchor", Vector3(0, 0.5, -2))
	add_marker(anchors, "CockpitAnchor", Vector3(0, 1, 0))
	add_marker(anchors, "LookTarget", Vector3(0, 1, -3))
	var rig := VehicleCameraRig.new()
	target.add_child(rig)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	await process_frame
	if rig.current_mode() != &"chase":
		fail("camera must start in chase mode")
		return
	Input.action_press("camera_next")
	await physics_frame
	Input.action_release("camera_next")
	await physics_frame
	if rig.current_mode() != &"hood":
		fail("camera_next must cycle chase to hood")
		return
	target.queue_free()
	await process_frame
	print("PASS: phase1 45_camera_input")
	quit(0)
