extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var path := "res://export_presets.cfg"
	if not FileAccess.file_exists(path):
		fail("export_presets.cfg must exist")
		return
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		fail("export presets must parse: %s" % error_string(error))
		return
	var names := PackedStringArray()
	for section in config.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			names.append(str(config.get_value(section, "name", "")))
	for required in ["Windows Desktop", "Linux"]:
		if required not in names:
			fail("missing export preset: %s" % required)
			return
	for index in [0, 1]:
		var section := "preset.%d.options" % index
		if not bool(config.get_value(section, "shader_baker/enabled", false)):
			fail("shader baker must be enabled for preset %d" % index)
			return
		if str(config.get_value(section, "binary_format/architecture", "")) != "x86_64":
			fail("preset %d must target x86_64" % index)
			return
	print("PASS: desktop export contract")
	quit(0)
