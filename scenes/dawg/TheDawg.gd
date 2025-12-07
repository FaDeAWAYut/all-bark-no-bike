extends CharacterBody2D

func _physics_process(delta):
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * 300
	move_and_slide()

func take_damage():
	# tell main to take damage
	if get_parent() and get_parent().has_method("player_take_damage"):
		get_parent().player_take_damage()