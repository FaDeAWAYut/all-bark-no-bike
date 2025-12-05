class_name Motorbike extends CharacterBody2D

var offset_from_camera: Vector2 = Vector2(0, 0)
@export var setSprite : String = "default"
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

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
@export var screen_bottom_y: float = 600 # Bottom boundary (pixels from top)

@export var HealthController: Node

signal motorbike_hidden

# Visual effects settings
@export_group("Hit Effects")
@export var hit_shake_intensity: float = 5.0
@export var hit_shake_duration: float = 0.3
@export var hit_flash_duration: float = 0.4
@export var hit_flash_color: Color = Color.RED

# Internal variables (accessible by states)
var direction: int = 1
var current_obstacle: Node2D = null
var escape_direction: int = 0
var currentSpeed: float

var is_hiding: bool = false
var is_hidden: bool = false
var is_showing: bool = false
var is_positioned: bool = true

# Visual effect variables
var original_position: Vector2
var shake_timer: float = 0.0
var shake_intensity: float = 0.0
var flash_tween: Tween
var shake_tween: Tween

# Module Instances
var speedManager: SpeedManager

@onready var ray_cast_left = $RayCastLeft
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_center = $RayCastCenter
@onready var state_machine = $StateMachine

@onready var motorbike_sprite = $Sprite2D

func _ready():
	# set sprite
	sprite.animation = StringName(setSprite)
	
	# Create and setup speed manager
	speedManager = SpeedManager.new()
	add_child(speedManager)
	
	# Calculate offset from camera
	var camera = get_viewport().get_camera_2d()
	if camera:
		offset_from_camera = global_position - camera.global_position
	
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	direction = 1 if randf() > 0.5 else -1
	
	# Store original position for shake effect
	original_position = global_position
	
	# Set initial position within screen bounds
	global_position.x = clamp(global_position.x, min_x, max_x)

func _physics_process(delta):
	currentSpeed = speedManager.update(delta)
	# All movement logic is now handled by the state machine
	update_shake_effect(delta)

func trigger_hit_effects():
	start_shake_effect()

func start_shake_effect():
	shake_intensity = hit_shake_intensity
	shake_timer = hit_shake_duration
	
	# Stop any existing shake tween
	if shake_tween:
		shake_tween.kill()
	
	# Create tween to gradually reduce shake intensity
	shake_tween = create_tween()
	shake_tween.tween_property(self, "shake_intensity", 0.0, hit_shake_duration)
	
func update_shake_effect(delta):
	if shake_timer > 0:
		# Apply random shake offset relative to current position
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		
		# Store the base position (without shake)
		var base_position = global_position
		
		# Apply shake offset
		global_position = base_position + shake_offset
		
		shake_timer -= delta
