class_name TestAssert
extends RefCounted

static var _failure_messages: Array[String] = []


static func reset() -> void:
	_failure_messages.clear()


static func failure_count() -> int:
	return _failure_messages.size()


static func failures() -> Array[String]:
	return _failure_messages.duplicate()


static func is_true(value: bool, message: String = "Expected true") -> void:
	if not value:
		_record_failure(message)


static func is_equal(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		return
	var resolved := message
	if resolved.is_empty():
		resolved = "Expected %s, got %s" % [str(expected), str(actual)]
	_record_failure(resolved)


static func is_near(
	actual: float,
	expected: float,
	tolerance: float,
	message: String = ""
) -> void:
	if absf(actual - expected) <= tolerance:
		return
	var resolved := message
	if resolved.is_empty():
		resolved = "Expected %f ± %f, got %f" % [expected, tolerance, actual]
	_record_failure(resolved)


static func _record_failure(message: String) -> void:
	_failure_messages.append(message)
	push_error(message)
