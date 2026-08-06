extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var logger_script := load("res://src/core/logger.gd")
	if logger_script == null:
		fail("logger script must load")
		return
	var logger = logger_script.new()
	logger.info(&"phase0", "logger online", {"build": "development"})
	var entries: Array = logger.get_recent_entries()
	if entries.size() != 1:
		fail("logger must retain one entry")
		return
	if entries[0]["category"] != &"phase0":
		fail("logger must retain category")
		return
	if entries[0]["message"] != "logger online":
		fail("logger must retain message")
		return
	logger.free()
	print("PASS: structured logger contract")
	quit(0)
