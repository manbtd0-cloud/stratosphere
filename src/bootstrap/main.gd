extends Node3D

const PROVING_REGION_SCENE := preload("res://scenes/world/proving_region.tscn")

func _ready() -> void:
	if get_node_or_null("ProvingRegion") != null:
		return
	var proving_region := PROVING_REGION_SCENE.instantiate()
	proving_region.name = "ProvingRegion"
	add_child(proving_region)
	print("Open-world racing Phase 2 proving region loaded.")
