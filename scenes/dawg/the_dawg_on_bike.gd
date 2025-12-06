extends CharacterBody2D

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * 300
	move_and_slide()

func _input(event):
	if event.is_action_pressed("shoot"):
		# Start charging when space is pressed
		if sprite.animation == &"default":
			sprite.animation = &"barking"
		elif sprite.animation == &"chadchart_active":
			sprite.animation = &"chadchart_active_barking"
		
	if event.is_action_released("shoot"):
		# Release charge when space is released
		if sprite.animation == &"barking":
			sprite.animation = &"default"
		elif sprite.animation == &"chadchart_active_barking":
			sprite.animation = &"chadchart_active"
		
