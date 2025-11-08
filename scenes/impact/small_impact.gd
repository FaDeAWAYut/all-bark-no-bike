extends Node2D

class_name SmallImpact

@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	# Play the animation
	anim_sprite.play("small_impact")
	
	# Connect the animation finished signal
	anim_sprite.animation_finished.connect(_on_animation_finished)
	

func _on_animation_finished():
	# Remove the impact effect when animation is done
	queue_free()
