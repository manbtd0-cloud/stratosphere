@tool
extends EditorScript

const FLIGHT_ROOM_SCENE := "res://scenes/flight_room/flight_room.tscn"
const GATE_POSITIONS := [
	Vector3(0.0, 18.0, -80.0),
	Vector3(55.0, 30.0, -175.0),
	Vector3(-35.0, 16.0, -270.0),
]
const LANDING_ZONE_POSITION := Vector3(0.0, 2.5, -340.0)


func _run() -> void:
	var packed := load(FLIGHT_ROOM_SCENE) as PackedScene
	if packed == null:
		push_error("Unable to load %s" % FLIGHT_ROOM_SCENE)
		return

	var root := packed.instantiate()
	for gate_index in range(GATE_POSITIONS.size()):
		var gate := root.get_node_or_null("Route/Gate%d" % gate_index) as RouteGate
		if gate == null:
			push_error("Missing route gate %d" % gate_index)
			root.free()
			return
		gate.gate_index = gate_index
		gate.position = GATE_POSITIONS[gate_index]

	var landing_zone := root.get_node_or_null("LandingZone") as Area3D
	if landing_zone == null:
		push_error("Missing LandingZone")
		root.free()
		return
	landing_zone.position = LANDING_ZONE_POSITION

	var rebuilt := PackedScene.new()
	var pack_error := rebuilt.pack(root)
	if pack_error != OK:
		push_error("Unable to pack flight room: %s" % error_string(pack_error))
		root.free()
		return

	var save_error := ResourceSaver.save(rebuilt, FLIGHT_ROOM_SCENE)
	root.free()
	if save_error != OK:
		push_error("Unable to save flight room: %s" % error_string(save_error))
		return
	print("Flight room route rebuilt at %s" % FLIGHT_ROOM_SCENE)