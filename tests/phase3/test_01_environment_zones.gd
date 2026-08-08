extends SceneTree
func fail(m:String)->void: push_error("FAIL: "+m); quit(1)
func _init()->void:
	var script=load("res://src/world/environment/environment_zone_definition.gd")
	if script==null: fail("EnvironmentZoneDefinition script must exist"); return
	var zone=script.new();zone.id=&"forest.north_hill";zone.zone_class=&"forest";zone.cell_ids.assign([&"world.proving.c-01_p02"]);zone.vegetation_palette_ids.assign([&"veg.conifer"]);zone.density_multiplier=1.0
	if not zone.validate().is_empty(): fail("valid zone rejected: %s"%zone.validate()); return
	zone.id=&"";if zone.validate().is_empty():fail("empty id must reject");return
	zone.id=&"forest.north_hill";zone.zone_class=&"lava";if zone.validate().is_empty():fail("unsupported class must reject");return
	zone.zone_class=&"forest";zone.cell_ids.clear();if zone.validate().is_empty():fail("zone must own at least one cell");return
	print("PASS: phase3 01_environment_zones");quit(0)
