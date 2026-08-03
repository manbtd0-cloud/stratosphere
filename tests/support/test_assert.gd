class_name TestAssert
extends RefCounted


static func is_true(value: bool, message: String = "Expected true") -> void:
	if not value:
		push_error(message)
	assert(value, message)


static func is_equal(actual: Variant, expected: Variant, message: String = "") -> void:
	var resolved := message
	if resolved.is_empty():
		resolved = "Expected %s, got %s" % [str(expected), str(actual)]
	if actual != expected:
		push_error(resolved)
	assert(actual == expected, resolved)


static func is_near(
	actual: float,
	expected: float,
	tolerance: float,
	message: String = ""
) -> void:
	var resolved := message
	if resolved.is_empty():
		resolved = "Expected %f ± %f, got %f" % [expected, tolerance, actual]
	var passed := absf(actual - expected) <= tolerance
	if not passed:
		push_error(resolved)
	assert(passed, resolved)
