extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _init()->void:call_deferred("run")
func _red_energies(root:Node)->Array[float]:
    var result:Array[float]=[];var stack:Array[Node]=[root]
    while not stack.is_empty():
        var n:Node=stack.pop_back()
        if n is MeshInstance3D:
            var mi:=n as MeshInstance3D
            for s in range(mi.mesh.get_surface_count()):
                var mat:=mi.get_active_material(s)
                if mat is StandardMaterial3D and mat.resource_name=="runtime_light_red":result.append(float((mat as StandardMaterial3D).emission_energy_multiplier))
        for child in n.get_children():stack.append(child)
    return result
func run()->void:
    var rig_script=load("res://src/vehicle/presentation/vehicle_visual_rig.gd")
    var effects_script=load("res://src/vehicle/presentation/vehicle_effects_bridge.gd")
    if effects_script==null:fail("effects bridge script must exist");return
    var holder=Node3D.new();root.add_child(holder)
    var fallback=Node3D.new();fallback.name="Fallback";holder.add_child(fallback)
    var rig=Node3D.new();rig.name="Rig";rig.set_script(rig_script);rig.fallback_path=NodePath("../Fallback");rig.auto_lod_enabled=false;holder.add_child(rig)
    await process_frame
    if not rig.is_runtime_visual_loaded():fail("real runtime 350Z must load for brake-light test");return
    var bridge=Node.new();bridge.set_script(effects_script);holder.add_child(bridge);bridge.bind_visual_rig(rig)
    bridge.apply_snapshot({"brake":0.0,"throttle":0.0,"gear":1,"body_contact_impulse":0.0,"wheels":{}})
    var low:=_red_energies(rig)
    if low.is_empty():fail("runtime red light material must be discoverable");return
    bridge.apply_snapshot({"brake":1.0,"throttle":0.0,"gear":1,"body_contact_impulse":0.0,"wheels":{}})
    var high:=_red_energies(rig)
    if high.is_empty() or high.max()<=low.max()+1.0:fail("brake input must raise red-light emission");return
    if not rig.set_lod(1):fail("LOD1 must load");return
    await process_frame
    bridge.apply_snapshot({"brake":1.0,"throttle":0.0,"gear":1,"body_contact_impulse":0.0,"wheels":{}})
    var rebuilt:=_red_energies(rig)
    if rebuilt.is_empty() or rebuilt.max()<=1.5:fail("brake-light binding must survive LOD rebuild");return
    holder.queue_free();await process_frame
    print("PASS: phase1 50_brake_light_binding")
    quit(0)
