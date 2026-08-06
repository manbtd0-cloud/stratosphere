extends SceneTree


func fail(message: String) -> void:
	push_error("FAIL: %s" % message)
	quit(1)


func _init() -> void:
	var data_script := load("res://src/persistence/save_data.gd")
	var service_script := load("res://src/persistence/save_service.gd")
	if data_script == null or service_script == null:
		fail("save scripts must load")
		return
	var root := "user://phase0-tests/saves"
	var service = service_script.new(root)
	service.delete_slot(1)

	var fresh = service.load_slot(1)
	if fresh.version != data_script.CURRENT_VERSION:
		fail("fresh save must use current version")
		return
	if fresh.money != 0 or fresh.reputation != 0:
		fail("fresh save must start empty")
		return

	var first = data_script.new()
	first.money = 1500
	first.reputation = 25
	first.owned_vehicles = PackedStringArray(["vehicle.prototype_rwd_coupe"])
	first.current_vehicle = &"vehicle.prototype_rwd_coupe"
	if service.write_slot(1, first) != OK:
		fail("first save write must succeed")
		return
	var loaded = service.load_slot(1)
	if loaded.money != 1500 or loaded.current_vehicle != &"vehicle.prototype_rwd_coupe":
		fail("save values must round-trip")
		return

	var second = data_script.new()
	second.money = 3000
	second.reputation = 50
	if service.write_slot(1, second) != OK:
		fail("second save write must succeed")
		return
	var backup_path := "%s/slot-1.bak" % root
	if not FileAccess.file_exists(backup_path):
		fail("second write must create backup")
		return

	var live_path := "%s/slot-1.json" % root
	var corrupt := FileAccess.open(live_path, FileAccess.WRITE)
	corrupt.store_string("{not valid json")
	corrupt.close()
	var recovered = service.load_slot(1)
	if recovered.money != 1500 or recovered.reputation != 25:
		fail("corrupt live save must recover last valid backup")
		return

	var future_payload := {"version": data_script.CURRENT_VERSION + 5, "money": 999}
	if not service.migrate(future_payload, int(future_payload["version"])).is_empty():
		fail("future save versions must be rejected")
		return

	service.free()
	fresh = null
	first = null
	loaded = null
	second = null
	recovered = null
	data_script = null
	service_script = null
	print("PASS: save service contract")
	quit(0)
