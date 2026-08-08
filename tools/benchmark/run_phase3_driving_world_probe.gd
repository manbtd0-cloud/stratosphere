extends SceneTree

func _init() -> void:
	var evidence := DrivingWorldProbe.new().run()
	if evidence.is_empty():
		push_error("FAIL: Phase 3 driving-world probe produced no evidence")
		quit(1)
		return
	print("PHASE3_PROBE %s" % JSON.stringify(evidence))
	print("PASS: phase3 driving-world deterministic probe")
	quit(0)
