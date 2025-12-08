extends Node2D

var direction = Vector2(0,0)

func _on_pressed(vector: Vector2) -> void:
	direction = vector
	
func _on_released():
	direction = Vector2(0,0)
