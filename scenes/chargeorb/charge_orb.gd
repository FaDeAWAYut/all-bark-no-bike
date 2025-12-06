extends Node2D

class_name ChargeOrb

@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	# Play the animation
	anim_sprite.play("charge_orb")
