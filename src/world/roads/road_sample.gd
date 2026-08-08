class_name RoadSample
extends RefCounted

var position: Vector3 = Vector3.ZERO
var forward: Vector3 = Vector3.FORWARD
var up: Vector3 = Vector3.UP
var right: Vector3 = Vector3.RIGHT
var accumulated_distance_m: float = 0.0
var half_road_width_m: float = 0.0
var shoulder_width_m: float = 0.0
var banking_radians: float = 0.0
