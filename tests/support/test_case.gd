class_name TestCase
extends RefCounted


func run() -> int:
	var count := 0
	for method_info in get_method_list():
		var method_name := String(method_info.name)
		if method_name.begins_with("test_"):
			call(method_name)
			count += 1
	return count
