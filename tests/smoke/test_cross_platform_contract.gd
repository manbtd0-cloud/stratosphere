extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var required_paths := PackedStringArray([
		"res://tools/verify/verify.ps1",
		"res://tools/verify/verify.sh",
	])
	for path in required_paths:
		if not FileAccess.file_exists(path):
			fail("missing cross-platform verification entrypoint: %s" % path)
			return
	print("PASS: cross-platform verification contract")
	quit(0)
