extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var packed=load("res://scenes/vehicle/prototype_rwd_coupe.tscn")
    if packed==null:fail("prototype scene must load");return
    var vehicle=packed.instantiate();root.add_child(vehicle);await process_frame
    var audio=vehicle.get_node_or_null("AudioBridge")
    var effects=vehicle.get_node_or_null("EffectsBridge")
    if audio==null:fail("production vehicle scene must include AudioBridge");return
    if effects==null:fail("production vehicle scene must include EffectsBridge");return
    if audio.get_script()==null or String(audio.get_script().resource_path)!="res://src/vehicle/presentation/vehicle_audio_bridge.gd":fail("AudioBridge must use production audio bridge script");return
    if effects.get_script()==null or String(effects.get_script().resource_path)!="res://src/vehicle/presentation/vehicle_effects_bridge.gd":fail("EffectsBridge must use production effects bridge script");return
    if audio.vehicle_path!=NodePath("..") or effects.vehicle_path!=NodePath(".."):fail("presentation bridges must consume parent vehicle telemetry");return
    if effects.visual_rig_path!=NodePath("../VisualRoot/VehicleVisualRig"):fail("effects bridge must bind the production visual rig");return
    vehicle.queue_free();await process_frame
    print("PASS: phase1 51_presentation_bridge_scene")
    quit(0)
