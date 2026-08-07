extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var audio_script=load("res://src/vehicle/presentation/vehicle_audio_bridge.gd")
    var effects_script=load("res://src/vehicle/presentation/vehicle_effects_bridge.gd")
    if audio_script==null or effects_script==null:fail("audio/effects bridge scripts must exist");return
    var snapshot={"speed_mps":24.0,"engine_rpm":5100.0,"engine_torque":145.0,"throttle":0.72,"brake":0.80,"gear":3,"body_contact_impulse":1400.0,"damage":{"severity":0.16},"wheels":{"fl":{"slip_energy":180.0,"surface":"asphalt_dry"},"fr":{"slip_energy":210.0,"surface":"asphalt_dry"},"rl":{"slip_energy":520.0,"surface":"asphalt_dry"},"rr":{"slip_energy":480.0,"surface":"asphalt_dry"}}}
    var audio:Dictionary=audio_script.build_state(snapshot,850.0,6800.0)
    if float(audio.get("engine_pitch_ratio",0.0))<=1.0:fail("engine pitch must rise with RPM");return
    if absf(float(audio.get("engine_load",0.0))-0.72)>0.001:fail("audio load must track throttle intent");return
    if float(audio.get("tire_slip_energy",0.0))<400.0:fail("audio state must expose tire slip energy");return
    if String(audio.get("dominant_surface",""))!="asphalt_dry":fail("audio state must expose dominant surface");return
    var effects:Dictionary=effects_script.build_state(snapshot)
    if float(effects.get("brake_light",0.0))<0.79:fail("effects state must expose brake-light demand");return
    if float(effects.get("skid_intensity",0.0))<=0.0:fail("effects state must expose skid intensity");return
    if float(effects.get("impact_intensity",0.0))<=0.0:fail("effects state must expose impact intensity");return
    if float(effects.get("exhaust_intensity",0.0))<=0.0:fail("effects state must expose exhaust intensity");return
    snapshot["gear"]=-1
    if not bool(effects_script.build_state(snapshot).get("reverse_active",false)):fail("reverse effect hook must follow reverse gear");return
    print("PASS: phase1 49_presentation_bridges")
    quit(0)
