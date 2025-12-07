extends Area2D

var velocity = Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position += velocity * delta

func launch(initial_velocity):
	velocity = initial_velocity

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage() 
		queue_free() 
		
func _on_screen_exited():
	queue_free()
