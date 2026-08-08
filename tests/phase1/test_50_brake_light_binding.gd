extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _init()->void:call_deferred("run")
func _red_energies(root:Node)->Array[float]:
    var result:Array[float]=[];var stack:Array[Node]=[root]
    while not stack.is_empty():
        var n:Node=stack.pop_back()
        if n is MeshInstance3D:
            var mi:=n as MeshInstance3D
            if mi.mesh!=null:
                for s in range(mi.mesh.get_surface_count()):
                    var mat:=mi.get_active_material(s)
                    if mat is StandardMaterial3D and mat.resource_name=="runtime_light_red":result.append(float((mat as StandardMaterial3D).emission_energy_multiplier))
        for child in n.get_children():stack.append(child)
    return result
func run()->void:
    var rig_script=load("res://src/vehicle/presentation/vehicle_visual_rig.gd")
    var effects_script=load("res://src/vehicle/presentation/vehicle_effects_bridge.gd")
    if rig_script==null or effects_script==null:fail("visual/effects bridge scripts must exist");return
    var holder=Node3D.new();root.add_child(holder)
    var fallback=Node3D.new();fallback.name="Fallback";holder.add_child(fallback)
    var rig=Node3D.new();rig.name="Rig";rig.set_script(rig_script);rig.fallback_path=NodePath("../Fallback");rig.auto_lod_enabled=false;holder.add_child(rig)
    await process_frame
    var runtime_loaded:bool=rig.is_runtime_visual_loaded()
    var bridge=Node.new();bridge.set_script(effects_script);holder.add_child(bridge);bridge.bind_visual_rig(rig)
    bridge.apply_snapshot({"brake":0.0,"throttle":0.0,"gear":1,"body_contact_impulse":0.0,"wheels":{}})
    if absf(float(bridge.last_state.get("brake_light",-1.0)))>0.001:fail("zero brake input must report zero brake-light demand");return
    if runtime_loaded:
        var low:=_red_energies(rig)
        if low.is_empty():fail("runtime red light material must be discoverable");return
        bridge.apply_snapshot({"brake":1.0,"throttle":0.0,"gear":1,"body_contact_impulse":0.0,"wheels":{}})
        var high:=_red_energies(rig)
        if high.is_empty() or high.max()<=low.max()+1.0:fail("brake input must raise red-light emission");return
        if not rig.set_lod(1):fail("LOD1 must load when runtime development GLBs are present");return
        await process_frame
        bridge.apply_snapshot({"brake":1.0,"throttle":0.0,"gear":1,"body_contact_impulse":0.0,"wheels":{}})
        var rebuilt:=_red_energies(rig)
        if rebuilt.is_empty() or rebuilt.max()<=1.5:fail("brake-light binding must survive LOD rebuild");return
    else:
        if not fallback.visible:fail("clean clone without runtime GLBs must show greybox fallback");return
        bridge.apply_snapshot({"brake":1.0,"throttle":0.0,"gear":1,"body_contact_impulse":0.0,"wheels":{}})
        if absf(float(bridge.last_state.get("brake_light",0.0))-1.0)>0.001:fail("effects bridge must preserve brake-light demand without presentation assets");return
        if rig.set_lod(1):fail("missing runtime GLB must not report successful LOD load");return
        if not fallback.visible:fail("fallback must remain visible after missing LOD request");return
    holder.queue_free();await process_frame
    print("PASS: phase1 50_brake_light_binding")
    quit(0)
