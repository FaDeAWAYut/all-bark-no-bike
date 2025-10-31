extends Sprite2D
@export var probability_left_turn: float = 1.0
@export var road_spawn_position: Vector2i = Vector2i(560, -500)
@export var turn_duration: float = 2.0
@export var turn_angle_degrees: float = 90.0
@export var base_turn_duration: float = 2.0
@export var speed_factor: float = 0.0005  # How much speed affects turn duration

@export var turn_offset_x: float = -2.0
@export var reset_delay: float = 3.0
@export var main_scene: Node
@export var base_pivot_offset: float = 0.0  # Base offset from screen center to start pivot
@export var speed_pivot_factor: float = 0.5  # How much speed affects when pivot starts

var screen_size: Vector2
var screen_height: float

var is_turning: bool = false
var is_hidden: bool = true

var camera: Camera2D
var distance_from_camera: float

@onready var timer: Timer = $Timer

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	screen_height = screen_size.y
	camera = get_viewport().get_camera_2d()
	distance_from_camera = abs(global_position.y - camera.global_position.y)
	
	# Connect timer timeout signal
	timer.timeout.connect(_on_timer_timeout)
	display_turn()

func _process(_delta: float) -> void:
	if is_turning:
		# Get the camera position to calculate relative position on screen
		
		if camera:
			# Get current game speed to calculate dynamic pivot trigger point
			var current_speed = 0.0
			if main_scene and main_scene.has_method("get") and "currentSpeed" in main_scene:
				current_speed = main_scene.currentSpeed
			
			# Calculate dynamic pivot trigger point - negative means earlier (above screen center)
			var dynamic_pivot_y = base_pivot_offset - (current_speed * speed_pivot_factor)
			
			# Calculate where this object appears on screen relative to camera
			var screen_position = global_position - camera.global_position

			# Check if the object has reached the dynamic pivot point
			if screen_position.y >= dynamic_pivot_y:
				turn_around_pivot()
				is_turning = false  # Prevent multiple calls


func display_turn():
	global_position = Vector2(global_position.x, camera.global_position.y - distance_from_camera)
	show()
	is_turning = true

func turn_around_pivot():
	# Calculate the final rotation
	var final_rotation = rotation_degrees + turn_angle_degrees
	
	# Get current game speed from main scene to adjust turn duration
	var current_speed = 0.0
	if main_scene and main_scene.has_method("get") and "currentSpeed" in main_scene:
		current_speed = main_scene.currentSpeed
	
	# Calculate dynamic turn duration based on speed
	var dynamic_turn_duration = base_turn_duration - (current_speed * speed_factor)
	dynamic_turn_duration = max(dynamic_turn_duration, 0.2)  # Minimum duration to prevent too fast turns
	
	# Create and configure the tween
	var tween = create_tween()
	
	# Animate rotation with dynamic duration
	tween.tween_property(self, "rotation_degrees", final_rotation, dynamic_turn_duration)
	
	# Reposition instantly
	global_position -= Vector2(turn_offset_x, 0)
	
	# After turn completes, wait 5 seconds then reset
	tween.tween_callback(_start_reset_delay)

func _start_reset_delay():
	# Create a new tween for the delay
	var delay_tween = create_tween()
	
	# Wait for reset_delay seconds then call reset_turn
	delay_tween.tween_interval(reset_delay)
	delay_tween.tween_callback(reset_turn)

func _on_timer_timeout():
	if is_visible_in_tree():
		return

	# Check probability and display turn if successful
	if randf() < probability_left_turn:
		display_turn()

func reset_turn():
	hide()

	global_position += Vector2(turn_offset_x, 0)
	rotation_degrees = 0.0
