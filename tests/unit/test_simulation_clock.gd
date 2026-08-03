class_name TestSimulationClock
extends TestCase


func test_sixty_hz_frame_produces_two_120_hz_ticks() -> void:
	var clock := SimulationClock.new(120.0)

	var ticks := clock.advance(1.0 / 60.0)

	TestAssert.is_equal(ticks, 2)
	TestAssert.is_near(clock.get_alpha(), 0.0, 0.000001)


func test_partial_time_remains_buffered() -> void:
	var clock := SimulationClock.new(120.0)

	TestAssert.is_equal(clock.advance(1.0 / 240.0), 0)
	TestAssert.is_near(clock.get_alpha(), 0.5, 0.000001)
	TestAssert.is_equal(clock.advance(1.0 / 240.0), 1)
	TestAssert.is_near(clock.get_alpha(), 0.0, 0.000001)


func test_negative_delta_produces_no_ticks() -> void:
	var clock := SimulationClock.new(120.0)

	TestAssert.is_equal(clock.advance(-1.0), 0)
	TestAssert.is_near(clock.get_alpha(), 0.0, 0.000001)