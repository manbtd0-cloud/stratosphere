class_name TransmissionSolver
extends RefCounted
static func ratio(config:TransmissionConfig,gear:int)->float:
	if gear<0:return config.reverse_ratio*config.final_drive
	if gear==0:return 0.0
	if gear>config.forward_ratios.size():return 0.0
	return config.forward_ratios[gear-1]*config.final_drive
static func automatic_gear(config:TransmissionConfig,current:int,road_rpm:float,throttle:float)->int:
	var g=clampi(current,1,config.forward_ratios.size())
	if road_rpm>config.upshift_rpm and g<config.forward_ratios.size():return g+1
	if road_rpm<config.downshift_rpm and g>1 and throttle<.95:return g-1
	return g
