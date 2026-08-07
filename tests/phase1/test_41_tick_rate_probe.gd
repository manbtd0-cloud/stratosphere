extends SceneTree
func _init():call_deferred("run")
func run():
 var ticks=120
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--ticks="):ticks=int(arg.trim_prefix("--ticks="))
 Engine.physics_ticks_per_second=ticks
 var lab=load("res://scenes/labs/vehicle_lab.tscn").instantiate();root.add_child(lab);await physics_frame
 var c=lab.get_node("PrototypeRwdCoupe") as VehicleController;c.debug_force_override=true
 for i in ticks:await physics_frame
 c.debug_throttle=1
 for i in ticks*5:await physics_frame
 print("TICK_RESULT ticks=%d speed=%.6f"%[ticks,c.linear_velocity.length()])
 lab.queue_free();await process_frame;quit(0)
