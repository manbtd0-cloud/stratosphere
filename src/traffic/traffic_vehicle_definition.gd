class_name TrafficVehicleDefinition
extends Resource

@export var id: StringName = &""
@export var mass_kg: float = 1350.0
@export var dimensions_m: Vector3 = Vector3(1.78, 1.45, 4.35)
@export var wheelbase_m: float = 2.62
@export var max_accel_mps2: float = 3.2
@export var max_brake_mps2: float = 7.0
@export var steering_torque_per_kg: float = 1.4
@export var path_divergence_recovery_m: float = 20.0
@export var recovery_delay_s: float = 3.0

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty(): errors.append("traffic vehicle id must not be empty")
	if mass_kg <= 100.0: errors.append("traffic vehicle mass must be plausible")
	if dimensions_m.x <= 0.5 or dimensions_m.y <= 0.5 or dimensions_m.z <= 1.0: errors.append("traffic vehicle dimensions must be positive")
	if wheelbase_m <= 1.0 or wheelbase_m >= dimensions_m.z: errors.append("traffic wheelbase must fit vehicle length")
	if max_accel_mps2 <= 0.0 or max_brake_mps2 <= 0.0: errors.append("traffic acceleration/braking limits must be positive")
	if recovery_delay_s <= 0.0 or path_divergence_recovery_m <= 0.0: errors.append("traffic recovery thresholds must be positive")
	return errors
