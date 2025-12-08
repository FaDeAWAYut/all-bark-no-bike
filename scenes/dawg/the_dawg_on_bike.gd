extends CharacterBody2D

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

@onready var useTouchscreen = DisplayServer.is_touchscreen_available()
var speed = 300
var direction

func _physics_process(delta):
	if useTouchscreen:
		#direction = $"../Joystick".get_joystick_dir()
		direction = $"../ArrowButtons".direction
	else:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = direction * speed
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
		
func take_damage():
	if get_parent() and get_parent().has_method("player_take_damage"):
		get_parent().player_take_damage()
