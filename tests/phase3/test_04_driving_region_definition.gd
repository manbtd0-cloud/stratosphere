extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
	var factory_script=load("res://src/world/proving/driving_region_factory.gd")
	if factory_script==null:fail("DrivingRegionFactory script must exist");return
	var region=factory_script.create()
	if region==null:fail("factory must create region");return
	var errors:PackedStringArray=region.validate()
	if not errors.is_empty():fail("canonical driving region invalid: %s"%errors);return
	if region.authored_cell_coords.size()<16 or region.authored_cell_coords.size()>22:fail("authored footprint must remain roughly 4-6 km2 at 512m cells");return
	var classes:Dictionary={}
	for zone in region.zones:classes[zone.zone_class]=true
	for required in EnvironmentZoneDefinition.ALLOWED_CLASSES:
		if not classes.has(required):fail("missing environment zone class: %s"%required);return
	if not region.facility_hooks.has(&"garage") or not region.facility_hooks.has(&"dealership"):fail("garage/dealership physical hooks required");return
	for hook in [&"garage",&"dealership"]:
		var t:Transform3D=region.facility_hooks[hook]
		if not t.origin.is_finite():fail("facility hook must be finite");return
	if not region.is_authored_connected():fail("authored cells must be one connected footprint");return
	print("PASS: phase3 04_driving_region_definition");quit(0)
