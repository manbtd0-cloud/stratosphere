class_name TelemetryRecorder
extends RefCounted
const VERSION:=1
var _samples:Array[Dictionary]=[]
var _run_name:=""
var _fingerprint:=""
func begin_run(run_name:String,definition:VehicleDefinition)->void:_samples.clear();_run_name=run_name.validate_filename();_fingerprint=definition.fingerprint()
func record(sample:Dictionary)->void:_samples.append(_json_safe(sample))
func finish(root_path:String="user://telemetry")->Dictionary:
	var base="%s/%s"%[root_path,_run_name];DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_path));var summary={"version":VERSION,"run":_run_name,"vehicle_definition_hash":_fingerprint,"godot_version":Engine.get_version_info().get("string","unknown"),"samples":_samples.size()}
	var jf=FileAccess.open(base+".json",FileAccess.WRITE);jf.store_string(JSON.stringify(summary,"\t"));jf.close();var jl=FileAccess.open(base+".jsonl",FileAccess.WRITE);for s in _samples:jl.store_line(JSON.stringify(s));jl.close();var cf=FileAccess.open(base+".csv",FileAccess.WRITE);cf.store_line("time,speed,rpm,gear");for s in _samples:cf.store_line("%.6f,%.6f,%.3f,%d"%[float(s.get("time",0)),float(s.get("speed_mps",0)),float(s.get("engine_rpm",0)),int(s.get("gear",0))]);cf.close();return summary
func _json_safe(v:Variant)->Variant:
	if v is Vector3:return [v.x,v.y,v.z]
	if v is Vector2:return [v.x,v.y]
	if v is Dictionary:
		var d={};for k in v:d[k]=_json_safe(v[k]);return d
	if v is Array:
		var a=[];for x in v:a.append(_json_safe(x));return a
	return v
