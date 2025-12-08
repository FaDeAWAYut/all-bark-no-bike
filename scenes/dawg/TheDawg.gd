extends CharacterBody2D

@onready var useTouchscreen = DisplayServer.is_touchscreen_available()
var speed = 300
var direction

func _physics_process(delta):
	if useTouchscreen:
		direction = $"../Joystick".get_joystick_dir()
	else:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = direction * speed
	move_and_slide()

func take_damage():
	# tell main to take damage
	if get_parent() and get_parent().has_method("player_take_damage"):
		get_parent().player_take_damage()
