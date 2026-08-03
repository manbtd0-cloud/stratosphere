class_name TestAssetManifestValidator
extends TestCase

const MANIFEST_PATH := "res://assets/generated/vtol_blockout.asset.json"
const RUNTIME_GLB_PATH := "res://assets/generated/vtol_blockout.glb"


func test_manifest_is_valid_and_complete() -> void:
	var result := AssetManifestValidator.validate_path(MANIFEST_PATH)

	TestAssert.is_true(
		result.is_valid,
		"Manifest validation failed: %s" % [result.errors]
	)


func test_manifest_uses_locked_orientation_and_units() -> void:
	var manifest := AssetManifestValidator.read_manifest(MANIFEST_PATH)

	TestAssert.is_equal(manifest.get("unit_scale_meters"), 1.0)
	TestAssert.is_equal(manifest.get("forward_axis"), "-Z")
	TestAssert.is_equal(manifest.get("up_axis"), "+Y")


func test_manifest_declares_required_gameplay_anchors() -> void:
	var manifest := AssetManifestValidator.read_manifest(MANIFEST_PATH)
	var required_nodes: Array = manifest.get("required_nodes", [])

	for node_name in [
		"VTOL_Blockout",
		"Body",
		"CockpitShell",
		"LeftEnginePod",
		"RightEnginePod",
		"CockpitAnchor",
		"ChaseAnchor",
		"ForwardMarker",
	]:
		TestAssert.is_true(required_nodes.has(node_name), "Missing required node: %s" % node_name)


func test_manifest_generation_paths_are_repository_relative() -> void:
	var manifest := AssetManifestValidator.read_manifest(MANIFEST_PATH)

	TestAssert.is_equal(
		manifest.get("generator"),
		"tools/blender/generate_vtol_blockout.py"
	)
	TestAssert.is_equal(
		manifest.get("source_blend"),
		"assets/source/vtol_blockout.blend"
	)
	TestAssert.is_equal(
		manifest.get("runtime_glb"),
		"assets/generated/vtol_blockout.glb"
	)


func test_exported_model_uses_godot_forward_axis() -> void:
	var packed: PackedScene = load(RUNTIME_GLB_PATH)
	var model := packed.instantiate()
	var forward_marker := model.get_node_or_null("ForwardMarker") as Node3D
	var cockpit_anchor := model.get_node_or_null("CockpitAnchor") as Node3D

	TestAssert.is_true(forward_marker != null, "GLB must contain ForwardMarker")
	TestAssert.is_true(cockpit_anchor != null, "GLB must contain CockpitAnchor")
	if forward_marker != null:
		TestAssert.is_true(
			forward_marker.position.z < 0.0,
			"ForwardMarker must point along Godot -Z"
		)
	if cockpit_anchor != null:
		TestAssert.is_true(
			cockpit_anchor.position.z < 0.0,
			"CockpitAnchor must remain toward the craft nose"
		)

	model.free()
