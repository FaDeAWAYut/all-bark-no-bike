extends Sprite2D
@export var timer_duration: float = 20.0
@export var probability_turn: float = 0.1 
@export var probability_left_turn: float = 1.0
@export var road_spawn_position: Vector2i = Vector2i(560, -500)
@export var turn_duration: float = 2.0
@export var turn_angle_degrees: float = 90.0
@export var base_turn_duration: float = 2.0
@export var speed_factor: float = 0.002  # How much speed affects turn duration

@export var turn_offset_x: float = -2.0
@export var reset_delay: float = 3.0
@export var main_scene: Node
@export var base_pivot_offset: float = 0.0  # Base offset from screen center to start pivot
@export var speed_pivot_factor: float = 0.5  # How much speed affects when pivot starts

@export_group("References")
@export var mainScene: Node
@export var motorbike: Node
@export var collectables_manager: CollectablesManager
@export var obstacle_spawner: ObstacleSpawner
var is_motorbike_hidden: bool = false
var is_item_drops_cleared: bool = false
var is_obstacles_cleared: bool = false

var screen_size: Vector2
var screen_height: float

var is_initialised: bool = false
var is_turning: bool = false
var is_hidden: bool = true

var camera: Camera2D
var distance_from_camera: float

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = timer_duration
	screen_size = get_viewport().get_visible_rect().size
	screen_height = screen_size.y
	camera = get_viewport().get_camera_2d()
	distance_from_camera = abs(global_position.y - camera.global_position.y)
	
	# Connect timer timeout signal
	timer.timeout.connect(_on_timer_timeout)
	
	# Connect to motorbike hidden signal
	if motorbike and motorbike.has_signal("motorbike_hidden"):
		motorbike.motorbike_hidden.connect(_on_motorbike_hidden)
	collectables_manager.collectables_cleared.connect(_on_collectables_cleared)
	obstacle_spawner.obstacles_cleared.connect(_on_obstacles_cleared)
	
	hide()

func _process(_delta: float) -> void:
	# Check if conditions are met to trigger display
	if is_motorbike_hidden and is_item_drops_cleared and is_obstacles_cleared:
		# Trigger display immediately and reset flags
		trigger_display()
		is_motorbike_hidden = false
		is_item_drops_cleared = false
		is_obstacles_cleared = false

	var current_speed = 0.0
	current_speed = main_scene.currentSpeed 
	
	# Move road turn downward while visible
	if is_visible():
		# Move downward at the current game speed
		global_position.y += current_speed * _delta * 2
	
	if is_turning:
		if camera:
			var dynamic_pivot_y = base_pivot_offset - (current_speed * speed_pivot_factor)
			var screen_position = global_position - camera.global_position
			if screen_position.y >= dynamic_pivot_y:
				turn_around_pivot()
				is_turning = false 

func _on_timer_timeout():
	if is_visible_in_tree():
		return

	if is_initialised:
		return

	if not motorbike.is_positioned:
		return

	# Check probability and display turn if successful
	if randf() < probability_turn:
		#check left or right turn
		is_initialised = true
		if randf() < probability_left_turn:
			turn_angle_degrees = 90.0
		else:
			turn_angle_degrees = -90.0
			flip_h = true
		display_turn() 
func display_turn():
	# Transition motorbike to turning state
	motorbike.state_machine._transition_to_next_state("Turning")
	collectables_manager.stop_spawning()
	obstacle_spawner.stop_spawning()

func _on_motorbike_hidden():
	if is_motorbike_hidden:
		return
	is_motorbike_hidden = true

func _on_collectables_cleared():
	if is_item_drops_cleared:
		return
	is_item_drops_cleared = true

func _on_obstacles_cleared():
	if is_obstacles_cleared:
		return
	is_obstacles_cleared = true

func trigger_display():
	is_turning = true
	global_position = Vector2(global_position.x, camera.global_position.y - distance_from_camera)
	if flip_h:
		global_position -= Vector2(turn_offset_x, 0)
	show()

func turn_around_pivot():
	# Calculate the final rotation
	var final_rotation = rotation_degrees + turn_angle_degrees
	
	# Get current game speed from main scene to adjust turn duration
	var current_speed = 0.0
	current_speed = main_scene.currentSpeed
	
	# Calculate dynamic turn duration based on speed
	var dynamic_turn_duration = base_turn_duration - (current_speed * speed_factor)
	dynamic_turn_duration = max(dynamic_turn_duration, 0.2)  # Minimum duration to prevent too fast turns
	
	# Create and configure the tween
	var tween = create_tween()
	
	# Animate rotation with dynamic duration
	tween.tween_property(self, "rotation_degrees", final_rotation, dynamic_turn_duration)
	
	if not flip_h:
		global_position -= Vector2(turn_offset_x, 0)
	else:
		global_position += Vector2(turn_offset_x, 0)

	# After turn completes, wait 5 seconds then reset
	tween.tween_callback(_start_reset_delay)

func _start_reset_delay():
	# Tell the turning state to start showing the motorbike
	var turning_state = motorbike.state_machine.get_node("Turning")
	if turning_state and motorbike.state_machine.state == turning_state:
		turning_state.start_showing()
	
	# Create a new tween for the delay
	var delay_tween = create_tween()
	
	# Wait for reset_delay seconds then call reset_turn
	delay_tween.tween_interval(reset_delay)
	delay_tween.tween_callback(reset_turn)

func reset_turn():
	collectables_manager.start_spawning()
	obstacle_spawner.start_spawning()
	hide()
	if not flip_h:
		global_position += Vector2(turn_offset_x, 0)
	else:
		flip_h = false
	rotation_degrees = 0.0
	is_initialised = false
	
	is_motorbike_hidden = false
	is_item_drops_cleared = false
	is_obstacles_cleared = false
