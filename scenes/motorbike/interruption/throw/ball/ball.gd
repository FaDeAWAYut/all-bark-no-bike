extends RigidBody2D

func _ready():
	body_entered.connect(_on_body_entered)

func launch(initial_velocity):
	linear_velocity = initial_velocity
	gravity_scale = 1.0 

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage()
		pass
