extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var packed=load("res://scenes/vehicle/prototype_rwd_coupe.tscn")
    if packed==null:fail("prototype vehicle scene must load");return
    var vehicle=packed.instantiate();root.add_child(vehicle);await process_frame
    var telemetry=vehicle.get_node_or_null("TelemetryEnricher")
    var recovery=vehicle.get_node_or_null("RecoveryCoordinator")
    if telemetry==null or recovery==null:fail("production scene must include telemetry enrichment and recovery coordinator");return
    if String(telemetry.get_script().resource_path)!="res://src/vehicle/telemetry/vehicle_telemetry_enricher.gd":fail("TelemetryEnricher must use production script");return
    if String(recovery.get_script().resource_path)!="res://src/vehicle/recovery/vehicle_recovery_coordinator.gd":fail("RecoveryCoordinator must use production script");return
    if telemetry.vehicle_path!=NodePath("..") or recovery.vehicle_path!=NodePath(".."):fail("vehicle services must consume parent vehicle state");return
    var validator=load("res://src/vehicle/validation/vehicle_asset_validator.gd")
    var errors:PackedStringArray=validator.validate_scene_contract(vehicle)
    if not errors.is_empty():fail("asset validator must require the production service nodes: %s"%[errors]);return
    vehicle.queue_free();await process_frame
    print("PASS: phase1 55_vehicle_services_scene")
    quit(0)
