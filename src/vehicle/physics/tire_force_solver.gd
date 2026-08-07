class_name TireForceSolver
extends RefCounted
static func normalized_curve(abs_slip:float,peak:float,post_peak:float)->float:
	if peak<=0:return 0.0
	var x=abs_slip/peak
	if x<=1.0:return sin(x*PI*.5)
	return lerpf(1.0,post_peak,clampf((x-1.0)/2.5,0.0,1.0))
static func calculate(config:TireConfig,normal_load:float,slip_ratio:float,slip_angle:float,surface:SurfaceConfig)->Dictionary:
	if normal_load<=0:return {"longitudinal":0.0,"lateral":0.0,"aligning_torque":0.0,"rolling_resistance":0.0,"slip_energy":0.0,"utilization":0.0}
	var load_scale=pow(maxf(normal_load/2900.0,.05),1.0-config.load_sensitivity);var peak_ratio=config.peak_slip_ratio*surface.optimal_slip_multiplier;var peak_angle=deg_to_rad(config.peak_slip_angle_deg)*surface.optimal_slip_multiplier;var fxn=normalized_curve(absf(slip_ratio),peak_ratio,config.post_peak_factor);var fyn=normalized_curve(absf(slip_angle),peak_angle,config.post_peak_factor);var fx=signf(slip_ratio)*fxn*config.mu_longitudinal*surface.friction_multiplier*normal_load*load_scale;var fy=-signf(slip_angle)*fyn*config.mu_lateral*surface.friction_multiplier*normal_load*load_scale;var maxf_total=surface.friction_multiplier*maxf(config.mu_longitudinal,config.mu_lateral)*normal_load*load_scale;var mag=sqrt(fx*fx+fy*fy)
	if mag>maxf_total and mag>0:var s=maxf_total/mag;fx*=s;fy*=s
	return {"longitudinal":fx,"lateral":fy,"aligning_torque":-fy*.04,"rolling_resistance":surface.rolling_resistance_coefficient*normal_load,"slip_energy":absf(fx*slip_ratio)+absf(fy*slip_angle),"utilization":clampf(mag/maxf(maxf_total,1.0),0,1)}
static func relax(previous:float,target:float,speed:float,length:float,delta:float)->float:
	var rate=maxf(absf(speed),1.0)/maxf(length,.01);return lerpf(previous,target,1.0-exp(-rate*maxf(delta,0.0)))
