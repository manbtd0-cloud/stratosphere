class_name ProvingRegionScene
extends Node3D

var _driving_definition: DrivingRegionDefinition
var _runtime: Node3D
var _player_vehicle: VehicleController
var _stream_manager: WorldStreamManager
var _navigation_service: NavigationService
var _traffic_lane_graph: TrafficLaneGraph
var _traffic_manager: TrafficManager
var _phase3_environment: Node3D
var _traffic_refresh_s: float = 0.0

func _ready() -> void:
	_driving_definition = DrivingRegionFactory.create()
	_runtime = DrivingRegionBuilder.new().build(_driving_definition)
	if _runtime == null:
		push_error("Unable to build Phase 3 driving region")
		return
	_runtime.name = "WorldRuntime"
	add_child(_runtime)
	_stream_manager = _runtime.get_node_or_null("TerrainRoot/WorldStreamManager") as WorldStreamManager
	_phase3_environment = _runtime.get_node_or_null("EnvironmentRoot/Phase3Environment") as Node3D
	var navigation_graph := NavigationGraphBuilder.new().build(_driving_definition.base_definition.road_network)
	_navigation_service = NavigationService.new(navigation_graph)
	_traffic_lane_graph = TrafficLaneGraphBuilder.new().build(_driving_definition.base_definition.road_network, _driving_definition.base_definition.grid)
	var traffic_root := Node3D.new(); traffic_root.name = "TrafficRoot"; _runtime.add_child(traffic_root)
	_traffic_manager = TrafficManager.new(); _traffic_manager.name = "TrafficManager"; traffic_root.add_child(_traffic_manager)
	var traffic_errors := _traffic_manager.configure(_traffic_lane_graph, TrafficRosterFactory.create_development_roster(), 12, 20)
	if not traffic_errors.is_empty(): push_error("Traffic configuration failed: %s" % traffic_errors)
	_spawn_player()
	if _stream_manager != null and _player_vehicle != null:
		_stream_manager.update_observer(_player_vehicle.global_position, _player_vehicle.linear_velocity)
		_sync_environment_visibility()
		_traffic_manager.spawn_to_target(_player_vehicle.global_transform, 1.0)

func _physics_process(delta: float) -> void:
	if _player_vehicle == null or _stream_manager == null: return
	_stream_manager.update_observer(_player_vehicle.global_position, _player_vehicle.linear_velocity)
	_sync_environment_visibility()
	if _traffic_manager != null:
		_traffic_manager.reconcile_loaded_cells(_stream_manager.loaded_cell_ids())
		_traffic_manager.update_simulation_levels(_player_vehicle.global_position)
		_traffic_refresh_s += delta
		if _traffic_refresh_s >= 1.0 or _traffic_manager.active_count() < 6:
			_traffic_refresh_s = 0.0
			_traffic_manager.spawn_to_target(_player_vehicle.global_transform, 1.0)

func _spawn_player() -> void:
	var packed := load("res://scenes/vehicle/prototype_rwd_coupe.tscn") as PackedScene
	if packed == null: return
	_player_vehicle = packed.instantiate() as VehicleController
	if _player_vehicle == null: return
	_player_vehicle.name = "PlayerVehicle"
	_player_vehicle.transform = _driving_definition.base_definition.spawn_transform
	add_child(_player_vehicle)

func _sync_environment_visibility() -> void:
	if _phase3_environment == null or _stream_manager == null: return
	var loaded: Dictionary = {}
	for raw_id in _stream_manager.loaded_cell_ids(): loaded[StringName(raw_id)] = true
	for child in _phase3_environment.get_children():
		if child is Node3D:
			(child as Node3D).visible = loaded.has(child.get_meta("cell_id", &""))

func get_player_vehicle() -> VehicleController: return _player_vehicle
func get_stream_manager() -> WorldStreamManager: return _stream_manager
func get_definition() -> ProvingRegionDefinition: return _driving_definition.base_definition if _driving_definition != null else null
func get_driving_region_definition() -> DrivingRegionDefinition: return _driving_definition
func get_navigation_service() -> NavigationService: return _navigation_service
func get_traffic_lane_graph() -> TrafficLaneGraph: return _traffic_lane_graph
func get_traffic_manager() -> TrafficManager: return _traffic_manager
