extends Node

class_name SpeedManager

signal speed_changed(new_speed)

var speed : float
var time : float
var startSpeed : float = 5.0
var maxSpeed : int = 100

func start():
	time = 0
	speed = startSpeed

func update(delta: float):
	time += delta
	
	if speed < maxSpeed and time >= 1:
		speed = startSpeed + ((time - 1) * 2)
		speed_changed.emit(speed)
	
	return speed

func get_speed() -> float:
	return speed
