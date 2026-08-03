class_name TestFlightRoomLoop
extends TestCase


func test_route_gates_only_advance_in_order() -> void:
	var room := FlightRoomController.new()
	room.configure_gate_count(3)

	TestAssert.is_true(not room.try_pass_gate(1))
	TestAssert.is_true(room.try_pass_gate(0))
	TestAssert.is_equal(room.get_next_gate_index(), 1)
	TestAssert.is_true(not room.try_pass_gate(2))
	TestAssert.is_true(room.try_pass_gate(1))
	TestAssert.is_true(room.try_pass_gate(2))
	TestAssert.is_equal(room.get_route_progress(), Vector2i(3, 3))

	room.free()


func test_landing_requires_all_gates_and_designated_zone() -> void:
	var room := FlightRoomController.new()
	room.configure_gate_count(2)
	room.set_landing_zone_occupied(true)

	TestAssert.is_true(not room.handle_landing())
	room.try_pass_gate(0)
	room.try_pass_gate(1)
	room.set_landing_zone_occupied(false)
	TestAssert.is_true(not room.handle_landing())
	room.set_landing_zone_occupied(true)
	TestAssert.is_true(room.handle_landing())
	TestAssert.is_equal(room.get_state(), FlightRoomController.STATE_COMPLETED)

	room.free()


func test_crash_and_restart_clear_route_state() -> void:
	var room := FlightRoomController.new()
	room.configure_gate_count(3)
	room.try_pass_gate(0)
	room.set_landing_zone_occupied(true)
	room.handle_crash()

	TestAssert.is_equal(room.get_state(), FlightRoomController.STATE_CRASHED)
	room.restart_run()

	TestAssert.is_equal(room.get_state(), FlightRoomController.STATE_FLYING)
	TestAssert.is_equal(room.get_next_gate_index(), 0)
	TestAssert.is_equal(room.get_route_progress(), Vector2i(0, 3))
	TestAssert.is_true(not room.is_landing_zone_occupied())

	room.free()


func test_pilot_control_is_enabled_only_while_flying() -> void:
	var room := FlightRoomController.new()
	room.configure_gate_count(1)

	TestAssert.is_true(room.is_pilot_control_enabled())
	room.handle_crash()
	TestAssert.is_true(not room.is_pilot_control_enabled())
	room.restart_run()
	TestAssert.is_true(room.is_pilot_control_enabled())
	room.try_pass_gate(0)
	room.set_landing_zone_occupied(true)
	room.handle_landing()
	TestAssert.is_true(not room.is_pilot_control_enabled())

	room.free()
