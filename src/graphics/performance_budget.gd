class_name PerformanceBudget
extends Resource


@export var target_fps: int = 60
@export var target_gpu_frame_ms: float = 14.5
@export var target_main_thread_ms: float = 8.0
@export var medium_vram_mb: int = 4096
@export var high_vram_mb: int = 6144


func frame_budget_ms() -> float:
	return 1000.0 / maxf(float(target_fps), 1.0)
