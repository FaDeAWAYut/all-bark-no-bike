extends Node

class_name SpeedManager

signal speed_changed(new_speed)

var speed : float
var time : float
@export var startSpeed : float = 150.0
@export var maxSpeed : float = 500.0

func start():
	time = 0
	speed = startSpeed

func update(delta: float):
	time += delta
	
	if speed < maxSpeed and time >= 1:
		speed = startSpeed + ((time - 1) * 20)
		speed_changed.emit(speed)
	
	return speed

func get_speed() -> float:
	return speed
