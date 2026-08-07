extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _init()->void:call_deferred("run")
func run()->void:
    var script=load("res://src/vehicle/telemetry/vehicle_telemetry_enricher.gd")
    if script==null:fail("VehicleTelemetryEnricher must exist");return
    var enricher=Node.new();enricher.set_script(script);root.add_child(enricher)
    var first={"time":1.0,"wheels":{"fl":{"compression":0.04,"surface":"asphalt_dry"},"fr":{"compression":0.04,"surface":"asphalt_wet"},"rl":{"compression":0.03,"surface":"gravel"},"rr":{"compression":0.03,"surface":"dirt"}}}
    var a:Dictionary=enricher.enrich_snapshot(first,0.01,0.016)
    var second={"time":1.01,"wheels":{"fl":{"compression":0.06,"surface":"asphalt_dry"},"fr":{"compression":0.03,"surface":"asphalt_wet"},"rl":{"compression":0.03,"surface":"gravel"},"rr":{"compression":0.04,"surface":"dirt"}}}
    var b:Dictionary=enricher.enrich_snapshot(second,0.01,0.016)
    var wheels:Dictionary=b.get("wheels",{})
    if absf(float(wheels["fl"].get("suspension_velocity_mps",0.0))-2.0)>0.01:fail("compression velocity must be derived per wheel");return
    if absf(float(wheels["fr"].get("suspension_velocity_mps",0.0))+1.0)>0.01:fail("rebound velocity must preserve sign");return
    if float(wheels["fr"].get("wetness",0.0))<0.99:fail("wet asphalt must expose wetness");return
    if float(wheels["fl"].get("wetness",1.0))>0.01:fail("dry asphalt must expose zero wetness");return
    var timing:Dictionary=b.get("timing",{})
    if absf(float(timing.get("physics_delta_s",0.0))-0.01)>0.0001:fail("physics delta must be exposed");return
    if absf(float(timing.get("physics_hz",0.0))-100.0)>0.1:fail("physics frequency must be derived");return
    if absf(float(timing.get("frame_delta_s",0.0))-0.016)>0.0001:fail("frame delta must be exposed");return
    if not timing.has("enrichment_usec"):fail("telemetry enrichment cost must be exposed");return
    enricher.queue_free();await process_frame
    print("PASS: phase1 53_telemetry_enrichment")
    quit(0)
