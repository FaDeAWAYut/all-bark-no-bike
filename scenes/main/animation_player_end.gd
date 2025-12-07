extends AnimationPlayer

@onready var parallaxBG: Parallax2D = $"../ParallaxBG".get_child(0)
@onready var startSpeed = 1000 # start speed of phase 2

var currentSpeed = 0
var scrollChangeStartTime = 0.0 # Start scrolling immediately
var scrollChangeEndTime = 6.0  # Slow down over 1 second
var sceneChangeTime = 32.0     # Change scene after 30 seconds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parallaxBG.scroll_offset.y = 10 # makes the intro bg align with level 1
	# Start at full speed then slow down
	parallaxBG.autoscroll.y = startSpeed

func _process(_delta: float) -> void:
	var currentAnimationPos = self.current_animation_position

	# Change scene after 30 seconds
	if currentAnimationPos >= sceneChangeTime:
		get_tree().change_scene_to_file("res://scenes/titlepage/title_page.tscn")
		return
	
	# Handle scrolling speed (fast to slow over 1 second)
	if currentAnimationPos >= scrollChangeEndTime:
		# After 1 second, keep at minimum speed (0 or very slow)
		parallaxBG.autoscroll.y = 0  # Or a small value like 50 if you want some movement
	elif currentAnimationPos >= scrollChangeStartTime:
		# Progress goes from 1.0 to 0.0 over 1 second (reverse of before)
		var progress = 1.0 - ((currentAnimationPos - scrollChangeStartTime) / (scrollChangeEndTime - scrollChangeStartTime))
		
		# Apply easing for smoother slowdown (optional)
		var eased_progress = ease(progress, 1.5)  # 1.5 = ease-out curve
		
		# Slow down from startSpeed to 0
		parallaxBG.autoscroll.y = eased_progress * startSpeed
