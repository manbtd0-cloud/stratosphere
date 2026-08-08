class_name ProvingRegionScene
extends Node3D

var _definition: ProvingRegionDefinition
var _runtime: Node3D
var _player_vehicle: VehicleController
var _stream_manager: WorldStreamManager

func _ready() -> void:
	_definition = ProvingRegionFactory.create()
	_runtime = ProvingRegionBuilder.new().build(_definition)
	if _runtime == null:
		push_error("Failed to build Phase 2 proving region runtime")
		return
	_runtime.name = "WorldRuntime"
	add_child(_runtime)
	_stream_manager = _runtime.get_node_or_null("TerrainRoot/WorldStreamManager") as WorldStreamManager
	var vehicle_scene := load("res://scenes/vehicle/prototype_rwd_coupe.tscn") as PackedScene
	if vehicle_scene == null:
		push_error("Prototype RWD coupe scene is unavailable")
		return
	_player_vehicle = vehicle_scene.instantiate() as VehicleController
	if _player_vehicle == null:
		push_error("Prototype RWD coupe failed to instantiate")
		return
	_player_vehicle.name = "PlayerVehicle"
	_player_vehicle.transform = _definition.spawn_transform
	add_child(_player_vehicle)

func _physics_process(_delta: float) -> void:
	if _player_vehicle != null and _stream_manager != null:
		_stream_manager.update_observer(_player_vehicle.global_position, _player_vehicle.linear_velocity)

func get_player_vehicle() -> VehicleController:
	return _player_vehicle

func get_stream_manager() -> WorldStreamManager:
	return _stream_manager

func get_definition() -> ProvingRegionDefinition:
	return _definition
