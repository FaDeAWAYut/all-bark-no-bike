extends Area2D

signal collide
signal end

func _ready() -> void: 
	$CollisionShape2D.disabled = false

func _on_body_entered(body: Node2D) -> void:
	hide()
	collide.emit()
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(5).timeout 
	end.emit()

func _process(delta: float) -> void:
	var old_position: Vector2 = position
	position = Vector2(old_position.x - 1, old_position.y - 0.5)
