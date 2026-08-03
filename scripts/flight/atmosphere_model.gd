class_name AtmosphereModel
extends RefCounted

const SEA_LEVEL_DENSITY_KG_M3: float = 1.225
const SCALE_HEIGHT_M: float = 8500.0


func density_at_altitude(altitude_m: float) -> float:
	var clamped_altitude := maxf(altitude_m, 0.0)
	return SEA_LEVEL_DENSITY_KG_M3 * exp(-clamped_altitude / SCALE_HEIGHT_M)
