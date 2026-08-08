class_name WorldGrid
extends RefCounted

const INVALID_COORD := Vector2i(2147483647, 2147483647)
const CELL_ID_PREFIX := "world.proving.c"

var cell_size: float
var half_extent_cells: int

func _init(cell_size_value: float = 512.0, half_extent_cells_value: int = 6) -> void:
	cell_size = cell_size_value
	half_extent_cells = half_extent_cells_value

func world_to_coord(position: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(position.x / cell_size)),
		int(floor(position.z / cell_size))
	)

func coord_to_center(coord: Vector2i) -> Vector3:
	return Vector3(
		(float(coord.x) + 0.5) * cell_size,
		0.0,
		(float(coord.y) + 0.5) * cell_size
	)

func coord_to_id(coord: Vector2i) -> StringName:
	if not is_valid_coord(coord):
		return &""
	return StringName("%s%s_%s" % [
		CELL_ID_PREFIX,
		_format_component(coord.x),
		_format_component(coord.y),
	])

func id_to_coord(cell_id: StringName) -> Vector2i:
	var text := String(cell_id)
	if not text.begins_with(CELL_ID_PREFIX):
		return INVALID_COORD
	var encoded := text.substr(CELL_ID_PREFIX.length())
	var parts := encoded.split("_", false)
	if parts.size() != 2:
		return INVALID_COORD
	var x_value = _parse_component(parts[0])
	var z_value = _parse_component(parts[1])
	if x_value == null or z_value == null:
		return INVALID_COORD
	var coord := Vector2i(int(x_value), int(z_value))
	return coord if is_valid_coord(coord) else INVALID_COORD

func is_valid_coord(coord: Vector2i) -> bool:
	return (
		coord.x >= -half_extent_cells
		and coord.x < half_extent_cells
		and coord.y >= -half_extent_cells
		and coord.y < half_extent_cells
	)

func neighbors(coord: Vector2i, radius: int = 1) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not is_valid_coord(coord) or radius < 1:
		return result
	for z_offset in range(-radius, radius + 1):
		for x_offset in range(-radius, radius + 1):
			if x_offset == 0 and z_offset == 0:
				continue
			var candidate := coord + Vector2i(x_offset, z_offset)
			if is_valid_coord(candidate):
				result.append(candidate)
	return result

func _format_component(value: int) -> String:
	if value < 0:
		return "-%02d" % abs(value)
	return "p%02d" % value

func _parse_component(encoded: String):
	if encoded.length() < 2:
		return null
	var digits := ""
	var sign := 1
	if encoded.begins_with("p"):
		digits = encoded.substr(1)
	elif encoded.begins_with("-"):
		digits = encoded.substr(1)
		sign = -1
	else:
		return null
	if digits.is_empty() or not digits.is_valid_int():
		return null
	return sign * int(digits)
