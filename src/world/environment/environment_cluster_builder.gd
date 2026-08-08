class_name EnvironmentClusterBuilder
extends RefCounted

func build_cluster(
	cluster_id: StringName,
	cell_id: StringName,
	mesh: Mesh,
	transforms: Array[Transform3D],
	density_multiplier: float = 1.0
) -> MultiMeshInstance3D:
	if cluster_id.is_empty() or cell_id.is_empty() or mesh == null:
		return null
	var density := clampf(density_multiplier, 0.0, 1.0)
	var desired_count := clampi(roundi(float(transforms.size()) * density), 0, transforms.size())
	var ranked: Array[Dictionary] = []
	for index in range(transforms.size()):
		var fingerprint := _transform_key(transforms[index])
		ranked.append({
			"score": ("%s|%s|%s" % [cluster_id, cell_id, fingerprint]).sha256_text(),
			"index": index,
			"fingerprint": fingerprint,
		})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.score == b.score:
			return int(a.index) < int(b.index)
		return String(a.score) < String(b.score)
	)
	var selected := ranked.slice(0, desired_count)
	selected.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.index) < int(b.index))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = desired_count
	var instance_ids := PackedStringArray()
	var combined_fingerprint := ""
	for output_index in range(selected.size()):
		var source_index: int = int(selected[output_index].index)
		var transform: Transform3D = transforms[source_index]
		multimesh.set_instance_transform(output_index, transform)
		var instance_id := "%s.%s.i%04d" % [cluster_id, cell_id, source_index]
		instance_ids.append(instance_id)
		combined_fingerprint += "%s=%s;" % [instance_id, selected[output_index].fingerprint]
	var instance := MultiMeshInstance3D.new()
	instance.name = "Cluster_%s" % String(cluster_id).replace(".", "_")
	instance.multimesh = multimesh
	instance.set_meta("cluster_id", cluster_id)
	instance.set_meta("cell_id", cell_id)
	instance.set_meta("instance_ids", instance_ids)
	instance.set_meta("transform_fingerprint", combined_fingerprint.sha256_text())
	instance.set_meta("source_instance_count", transforms.size())
	instance.set_meta("density_multiplier", density)
	return instance

func _transform_key(transform: Transform3D) -> String:
	var values := [
		transform.origin.x, transform.origin.y, transform.origin.z,
		transform.basis.x.x, transform.basis.x.y, transform.basis.x.z,
		transform.basis.y.x, transform.basis.y.y, transform.basis.y.z,
		transform.basis.z.x, transform.basis.z.y, transform.basis.z.z,
	]
	var parts := PackedStringArray()
	for value in values:
		parts.append("%.4f" % snappedf(float(value), 0.0001))
	return ",".join(parts)
