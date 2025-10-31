extends Sprite2D
@export var road_spawn_position: Vector2i = Vector2i(560, -500)
@export var turn_duration: float = 2.0
@export var turn_angle_degrees: float = 90.0

@export var turn_offset_x: float = -2.0
@export var reset_delay: float = 5.0

var screen_size: Vector2
var screen_height: float

var is_turning: bool = false

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	screen_height = screen_size.y
	reset_turn()

func _process(_delta: float) -> void:
	if is_turning:
		# Get the camera position to calculate relative position on screen
		var camera = get_viewport().get_camera_2d()
		if camera:
			# Calculate where this object appears on screen relative to camera
			var screen_position = global_position - camera.global_position
			var screen_center_y = 0  # Camera center is at 0,0 in screen space

			# Check if the object has reached the center of the screen
			if screen_position.y >= screen_center_y:
				turn_around_pivot()
				is_turning = false  # Prevent multiple calls

func display_turn():
	show()
	is_turning = true

func turn_around_pivot():
	# Calculate the final rotation
	var final_rotation = rotation_degrees + turn_angle_degrees
	
	# Create and configure the tween
	var tween = create_tween()
	
	# Animate rotation
	tween.tween_property(self, "rotation_degrees", final_rotation, turn_duration)
	
	# Reposition instantly
	global_position += Vector2(turn_offset_x, 0)
	
	# After turn completes, wait 5 seconds then reset
	tween.tween_callback(_start_reset_delay)

func _start_reset_delay():
	# Create a new tween for the delay
	var delay_tween = create_tween()
	
	# Wait for reset_delay seconds then call reset_turn
	delay_tween.tween_interval(reset_delay)
	delay_tween.tween_callback(reset_turn)

func reset_turn():
	rotation_degrees = 0.0
	global_position = road_spawn_position
	hide()
