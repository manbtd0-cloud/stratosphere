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
	var manifest_path := "res://tests/test_manifest.txt"
	if not FileAccess.file_exists(manifest_path):
		fail("shared test manifest must exist")
		return
	for wrapper_path in required_paths:
		var wrapper := FileAccess.open(wrapper_path, FileAccess.READ)
		if wrapper == null or not wrapper.get_as_text().contains("test_manifest.txt"):
			fail("verification wrapper must consume shared test manifest: %s" % wrapper_path)
			return
	print("PASS: cross-platform verification contract")
	quit(0)
