class_name TestAtmosphereModel
extends TestCase


func test_sea_level_and_negative_altitude_use_sea_level_density() -> void:
	var atmosphere := AtmosphereModel.new()
	TestAssert.is_near(atmosphere.sample_density(0.0), 1.225, 0.000001)
	TestAssert.is_near(atmosphere.sample_density(-100.0), 1.225, 0.000001)


func test_density_decreases_with_altitude() -> void:
	var atmosphere := AtmosphereModel.new()
	var sea_level := atmosphere.sample_density(0.0)
	var five_km := atmosphere.sample_density(5000.0)
	var ten_km := atmosphere.sample_density(10000.0)

	TestAssert.is_true(five_km < sea_level)
	TestAssert.is_true(ten_km < five_km)
	TestAssert.is_true(ten_km > 0.0)