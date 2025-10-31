extends CharacterBody2D

class_name Motorbike

@export var spawn_position: Vector2 = Vector2(800, 2000)
var offset_from_camera: Vector2 = Vector2(0, 0)

# Movement settings
@export var speed_x: float = 120.0
@export var escape_speed: float = 500.0
@export var min_x: float = 350.0
@export var max_x: float = 1600.0
@export var change_direction_time: float = 2.0


@export var hide_speed_multiplier:= 1.5

# Obstacle detection settings
@export var obstacle_check_rate: float = 0.2

# Screen boundaries (adjust these based on your camera/screen size)
@export var screen_top_y: float = 150.0    # Top boundary (pixels from top)
@export var screen_bottom_y: float = 300.0 # Bottom boundary (pixels from top)

# Internal variables
var direction: int = 1
var timer: float = 0.0
var obstacle_timer: float = 0.0
var current_obstacle: Node2D = null
var escape_direction: int = 0
var currentSpeed: float

var is_hiding: bool = false
var is_hidden: bool = false
var is_showing: bool = false

signal motorbike_hidden

# Module Instances
var speedManager: SpeedManager

@onready var ray_cast_left = $RayCastLeft
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_center = $RayCastCenter

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
	global_position.y = randf_range(screen_top_y, screen_bottom_y)

func _physics_process(delta):
	timer += delta
	obstacle_timer += delta
	
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
		velocity.y = -currentSpeed * 0.5
		
		var camera = get_viewport().get_camera_2d()
		if camera:
			var target_y = camera.global_position.y + offset_from_camera.y
			if global_position.y >= target_y:
				global_position.y = target_y
				is_showing = false
				is_hidden = false
		
		move_and_slide()
		return
	
	# Check for obstacles periodically
	if obstacle_timer >= obstacle_check_rate:
		check_for_obstacles()
		obstacle_timer = 0.0
	
	# Handle movement based on obstacle presence
	if current_obstacle:
		handle_obstacle_escape()
	else:
		handle_normal_movement()

	enforce_boundaries()
	move_and_slide()

func handle_normal_movement():
	# Change direction when timer reaches threshold
	if timer >= change_direction_time:
		change_direction()
		timer = 0.0
	
	# Move only horizontally (no vertical movement since camera is static)
	velocity.x = direction * speed_x
	velocity.y = 0  # No vertical movement

func handle_obstacle_escape():
	# Move away from obstacle (only horizontally)
	velocity.x = escape_direction * escape_speed
	velocity.y = 0  # No vertical movement

func check_for_obstacles():
	current_obstacle = null
	escape_direction = 0
	
	# Check all raycasts for obstacles
	var obstacles = []
	
	if ray_cast_center and ray_cast_center.is_colliding():
		var obstacle = ray_cast_center.get_collider()
		if obstacle and obstacle != self:
			obstacles.append(obstacle)
			# Determine escape direction based on obstacle position
			var obstacle_pos = ray_cast_center.get_collision_point()
			escape_direction = 1 if obstacle_pos.x < global_position.x else -1
	
	# Check side raycasts for better decision making
	if ray_cast_left and ray_cast_left.is_colliding():
		var obstacle = ray_cast_left.get_collider()
		if obstacle and obstacle != self:
			obstacles.append(obstacle)
			escape_direction = 1  # Move right if obstacle on left
	
	if ray_cast_right and ray_cast_right.is_colliding():
		var obstacle = ray_cast_right.get_collider()
		if obstacle and obstacle != self:
			obstacles.append(obstacle)
			escape_direction = -1  # Move left if obstacle on right
	
	# If we found obstacles, set current obstacle
	if obstacles.size() > 0:
		current_obstacle = obstacles[0]
		# If we haven't determined escape direction, choose randomly
		if escape_direction == 0:
			escape_direction = 1 if randf() > 0.5 else -1

func change_direction():
	direction = 1 if randf() > 0.5 else -1

func enforce_boundaries():
	# Horizontal boundaries
	if global_position.x <= min_x:
		global_position.x = min_x
		if direction == -1:
			direction = 1
		if escape_direction == -1:
			escape_direction = 1
	elif global_position.x >= max_x:
		global_position.x = max_x
		if direction == 1:
			direction = -1
		if escape_direction == 1:
			escape_direction = -1
	
	# Vertical boundaries (keep within top half of screen)
	if global_position.y <= screen_top_y:
		global_position.y = screen_top_y
	elif global_position.y >= screen_bottom_y:
		global_position.y = screen_bottom_y

func hide_motorbike():
	if is_hidden:
		return

	is_hiding = true
	
	# Clear current obstacle state
	current_obstacle = null
	escape_direction = 0
	
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
	show()
	is_showing = true
