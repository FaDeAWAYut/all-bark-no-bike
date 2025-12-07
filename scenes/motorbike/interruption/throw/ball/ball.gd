extends RigidBody2D

func _ready():
	body_entered.connect(_on_body_entered)

func launch(initial_velocity):
	linear_velocity = initial_velocity

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage()
		pass
