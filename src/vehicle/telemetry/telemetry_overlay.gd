class_name TelemetryOverlay
extends CanvasLayer
@export var vehicle_path:NodePath
var label:Label
func _ready()->void:
	label=Label.new();label.name="TelemetryLabel";label.position=Vector2(16,16);add_child(label)
func _process(_delta:float)->void:
	var v=get_node_or_null(vehicle_path);if v==null or label==null:return
	var t:Dictionary=v.get_telemetry_snapshot();var w:Dictionary=t.get("wheels",{});label.text="%.1f km/h  %d rpm  G%d  TCS %.2f  DMG %.2f\nFL slip %.2f %s  RL slip %.2f %s"%[float(t.get("speed_mps",0))*3.6,int(t.get("engine_rpm",0)),int(t.get("gear",0)),float(t.get("tcs_factor",1)),float(t.get("damage",{}).get("severity",0)),float(w.get("fl",{}).get("slip_ratio",0)),String(w.get("fl",{}).get("surface","")),float(w.get("rl",{}).get("slip_ratio",0)),String(w.get("rl",{}).get("surface",""))]
