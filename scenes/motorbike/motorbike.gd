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

func _physics_process(delta):
	currentSpeed = speedManager.update(delta)
	# All movement logic is now handled by the state machine
