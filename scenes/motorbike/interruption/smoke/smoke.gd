extends Area2D

@onready var timer = $Timer

func _ready():
	timer.timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
#		gameManager.reduce_HP(5)
		queue_free()
