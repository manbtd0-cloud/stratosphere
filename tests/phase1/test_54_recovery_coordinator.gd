extends SceneTree
func fail(message:String)->void:push_error("FAIL: %s"%message);quit(1)
func _init()->void:
    var script=load("res://src/vehicle/recovery/vehicle_recovery_coordinator.gd")
    if script==null:fail("VehicleRecoveryCoordinator must exist");return
    if not script.should_record_safe_transform(0.95,4,12.0):fail("upright grounded driving state should be recoverable");return
    if script.should_record_safe_transform(0.20,4,0.0):fail("inverted car must never overwrite recovery transform");return
    if script.should_record_safe_transform(0.95,1,0.0):fail("single-wheel contact must not become safe recovery state");return
    if not script.should_auto_recover(0.10,0.4,3.2,2.5):fail("settled inverted vehicle must auto recover after delay");return
    if script.should_auto_recover(0.10,8.0,5.0,2.5):fail("moving vehicle must not auto recover");return
    if script.should_auto_recover(0.80,0.0,5.0,2.5):fail("upright vehicle must not auto recover");return
    print("PASS: phase1 54_recovery_coordinator")
    quit(0)
