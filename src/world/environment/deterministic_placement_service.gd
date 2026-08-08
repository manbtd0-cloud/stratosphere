class_name DeterministicPlacementService
extends RefCounted

const MAX_ATTEMPTS_PER_INSTANCE := 96

func generate(
	zone: EnvironmentZoneDefinition,
	cell_id: StringName,
	layer_id: StringName,
	bounds: AABB,
	count: int,
	min_spacing: float
) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	if zone == null or not zone.validate().is_empty() or cell_id.is_empty() or layer_id.is_empty():
		return result
	if count <= 0:
		return result
	if bounds.size.x <= 0.0 or bounds.size.z <= 0.0 or min_spacing < 0.0:
		return result
	# Cheap feasibility bound prevents obviously impossible requests from burning attempts.
	if min_spacing > 0.0:
		var estimated_capacity := int(floor((bounds.size.x / min_spacing + 1.0) * (bounds.size.z / min_spacing + 1.0)))
		if count > estimated_capacity:
			return result
	var rng := RandomNumberGenerator.new()
	rng.seed = _stable_seed(zone.id, cell_id, layer_id)
	var attempts := 0
	var max_attempts := maxi(count * MAX_ATTEMPTS_PER_INSTANCE, MAX_ATTEMPTS_PER_INSTANCE)
	while result.size() < count and attempts < max_attempts:
		attempts += 1
		var position := Vector3(
			rng.randf_range(bounds.position.x, bounds.end.x),
			bounds.position.y,
			rng.randf_range(bounds.position.z, bounds.end.z)
		)
		if not _is_spaced(position, result, min_spacing):
			continue
		var yaw := rng.randf_range(-PI, PI)
		result.append(Transform3D(Basis(Vector3.UP, yaw), position))
	if result.size() != count:
		result.clear()
	return result

func _stable_seed(zone_id: StringName, cell_id: StringName, layer_id: StringName) -> int:
	var digest := ("%s|%s|%s" % [zone_id, cell_id, layer_id]).sha256_text()
	return digest.substr(0, 15).hex_to_int()

func _is_spaced(position: Vector3, existing: Array[Transform3D], min_spacing: float) -> bool:
	if min_spacing <= 0.0:
		return true
	var min_sq := min_spacing * min_spacing
	for transform in existing:
		var delta := transform.origin - position
		delta.y = 0.0
		if delta.length_squared() < min_sq:
			return false
	return true
