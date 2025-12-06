extends Area2D


func _ready() -> void: 
	$CollisionShape2D.set_deferred("disabled", false)

func _process(_delta: float) -> void:
	var old_position: Vector2 = position
	position = Vector2(old_position.x - 1, old_position.y + 1)
