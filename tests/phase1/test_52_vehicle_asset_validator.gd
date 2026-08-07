extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _load_json(path:String)->Dictionary:
    var f=FileAccess.open(path,FileAccess.READ);return JSON.parse_string(f.get_as_text()) if f else {}
func _init()->void:call_deferred("run")
func run()->void:
    var script=load("res://src/vehicle/validation/vehicle_asset_validator.gd")
    if script==null:fail("production VehicleAssetValidator must exist");return
    var manifest:=_load_json("res://assets/source/vehicle/prototype_rwd_coupe/source_manifest.json")
    var audit:=_load_json("res://assets/source/vehicle/prototype_rwd_coupe/runtime_audit.json")
    var errors:PackedStringArray=script.validate_metadata(manifest,audit)
    if not errors.is_empty():fail("current 350Z metadata must pass validator: %s"%[errors]);return
    var bad_lod=audit.duplicate(true);bad_lod["lods"]["lod0"]["triangles"]=999999
    if script.validate_metadata(manifest,bad_lod).is_empty():fail("validator must reject over-budget LOD0");return
    var bad_texture=audit.duplicate(true);bad_texture["texture_payload"]["images"]=0
    if script.validate_metadata(manifest,bad_texture).is_empty():fail("validator must reject missing required embedded texture payload");return
    if script.release_errors(manifest).is_empty():fail("release validator must block unverified source licensing");return
    var packed=load("res://scenes/vehicle/prototype_rwd_coupe.tscn");var vehicle=packed.instantiate();root.add_child(vehicle);await process_frame
    var scene_errors:PackedStringArray=script.validate_scene_contract(vehicle)
    if not scene_errors.is_empty():fail("production vehicle scene must pass asset scene contract: %s"%[scene_errors]);return
    vehicle.queue_free();await process_frame
    print("PASS: phase1 52_vehicle_asset_validator")
    quit(0)
