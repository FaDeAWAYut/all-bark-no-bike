extends AnimationPlayer

@onready var parallaxBG:Parallax2D = $"../ParallaxBG".get_child(0)
@onready var startSpeed = 400 # start speed of phase 2; if start_speed of phase 2 in SpeedManager changes, we must change this too
var currentSpeed = 0
var scrollChangeStartTime = 6.5 # when to start scroll
var scrollChangeEndTime = 10 # when to reach start speed of level 1
 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parallaxBG.scroll_offset.y = 35 # makes the intro bg align with level 1


func _process(_delta: float) -> void:
	var currentAnimationPos = self.current_animation_position

	if currentAnimationPos >= self.current_animation_length:
		get_tree().change_scene_to_file("res://scenes/main/phase2.tscn")
	
	if currentAnimationPos >= scrollChangeEndTime:
		pass
	elif currentAnimationPos >= scrollChangeStartTime:
		var progress = (currentAnimationPos-scrollChangeStartTime)/(scrollChangeEndTime-scrollChangeStartTime)
		parallaxBG.autoscroll.y = progress * startSpeed
