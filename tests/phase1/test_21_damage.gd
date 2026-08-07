extends SceneTree
func fail(m:String)->void:push_error("FAIL: "+m);quit(1)
func _init()->void:
    var c=DamageConfig.new();var d=DamageState.new();d.apply_impulse(c.severe_impulse,c)
    if d.severity<.99 or d.power_multiplier>=1:fail("damage modifiers");return
    d.repair()
    if d.severity!=0 or d.power_multiplier!=1:fail("repair");return
    print("PASS: test_21_damage")
    quit(0)
