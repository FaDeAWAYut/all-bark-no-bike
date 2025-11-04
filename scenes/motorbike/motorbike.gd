class_name Motorbike extends CharacterBody2D

@export var spawn_position: Vector2 = Vector2(448, 150)
var offset_from_camera: Vector2 = Vector2(0, 0)

# Movement settings
@export var speed_x: float = 200.0
@export var escape_speed: float = 400.0
@export var min_x: float = 190.0
@export var max_x: float = 710.0
@export var direction_rotation_angle: float = 0.05 # radian
@export var direction_rotation_speed: float = 40.0

@export var hide_speed_multiplier:= 1.5

# Obstacle detection settings
@export var obstacle_check_rate: float = 0.1

# Screen boundaries (adjust these based on your camera/screen size)
@export var screen_top_y: float = 150.0    # Top boundary (pixels from top)
@export var screen_bottom_y: float = 300.0 # Bottom boundary (pixels from top)

@export var BossHealthController: Node

# Internal variables (accessible by states)
var direction: int = 1
var current_obstacle: Node2D = null
var escape_direction: int = 0
var currentSpeed: float

var is_hiding: bool = false
var is_hidden: bool = false
var is_showing: bool = false
var is_positioned: bool = true

signal motorbike_hidden

# Module Instances
var speedManager: SpeedManager

@onready var ray_cast_left = $RayCastLeft
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_center = $RayCastCenter
@onready var state_machine = $StateMachine

func _ready():
	# Create and setup speed manager
	speedManager = SpeedManager.new()
	add_child(speedManager)
	
	# Calculate offset from camera
	var camera = get_viewport().get_camera_2d()
	if camera:
		offset_from_camera = global_position - camera.global_position
	
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	direction = 1 if randf() > 0.5 else -1
	
	# Set initial position within screen bounds
	global_position.x = clamp(global_position.x, min_x, max_x)
	#global_position.y = randf_range(screen_top_y, screen_bottom_y)

func _physics_process(delta):
	currentSpeed = speedManager.update(delta)
	
	if is_hiding:
		# Use increased velocity to speed up the bike when hiding
		velocity.x = 0  # Stop horizontal movement
		velocity.y = -1 * currentSpeed * hide_speed_multiplier
		
		# Check if bike is outside camera viewport
		var camera = get_viewport().get_camera_2d()
		if camera:
			var screen_size = get_viewport().get_visible_rect().size
			var camera_top = camera.global_position.y - screen_size.y / 2
			
			# If bike is above the camera viewport, emit signal and hide
			if global_position.y < camera_top - 100:  # Add 100px buffer
				hide()
				motorbike_hidden.emit()
				is_hiding = false
				is_hidden = true
		move_and_slide()
		return

	if is_showing:
		velocity.x = 0  # Stop horizontal movement while showing
		velocity.y = currentSpeed * hide_speed_multiplier
		
		var camera = get_viewport().get_camera_2d()
		if camera:
			var target_y = camera.global_position.y + offset_from_camera.y
			if global_position.y >= target_y:
				global_position.y = target_y
				is_showing = false
				is_hidden = false
				is_positioned = true
		move_and_slide()
		return
	
	# State machine now handles the driving logic

# Driving logic has been moved to the Driving state

func hide_motorbike():
	if is_hidden:
		return

	if not is_positioned:
		return

	is_hiding = true
	is_positioned = false
	
	# Clear current obstacle state - these are used by the driving state
	current_obstacle = null
	escape_direction = 0
	direction = 0
	
	# Disable raycasts
	if ray_cast_left:
		ray_cast_left.enabled = false
	if ray_cast_right:
		ray_cast_right.enabled = false
	if ray_cast_center:
		ray_cast_center.enabled = false

func show_motorbike():
	if not is_hidden:
		return

	# Re-enable raycasts
	if ray_cast_left:
		ray_cast_left.enabled = true
	if ray_cast_right:
		ray_cast_right.enabled = true
	if ray_cast_center:
		ray_cast_center.enabled = true

	var screen_size = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_2d()
	# Position at top of camera viewport + screen height above
	var camera_top = camera.global_position.y - screen_size.y / 2
	var target = camera_top - screen_size.y  # This puts it one screen height above the top

	global_position = Vector2(global_position.x, target)
	direction = 0
	show()
	is_showing = true
