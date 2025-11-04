extends Node

@export var max_health: int = 100
var current_health: int

signal health_changed(new_health: int)
signal died

func _ready():
	current_health = max_health

func take_damage(damage_amount: int):
	current_health = max(0, current_health - damage_amount)
	health_changed.emit(current_health)
	
	if current_health <= 0:
		died.emit()

func restore_health(heal_amount: int):
	current_health = min(max_health, current_health + heal_amount)
	health_changed.emit(current_health)
