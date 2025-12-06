extends Area2D
@onready var road_turn: Node2D = $".."

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		road_turn.mainScene.player_take_damage()
