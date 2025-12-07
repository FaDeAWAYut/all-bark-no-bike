extends MotorbikeFriendState

@onready var waiting_timer : Timer = $WaitingTimer

@export var sprite_height: float = 200.0
@export var slide_down_duration: float = 1.0
@export var slide_back_duration: float = 1.0

var is_moving_down: bool = false
var is_moving_back: bool = false
var original_position: Vector2
var current_down_position: Vector2
var slide_timer: float = 0.0
var target_y: float = 0.0
var main_scene: Node = null

func enter(_previous_state_path: String, _data := {}) -> void:
	if not boss:
		return
	
	# Set timer to finish waiting
	waiting_timer.wait_time = $"../..".entrance_time
	waiting_timer.start()
	
	# Store original position (the position to return to after stun)
	original_position = boss.global_position
	
	# Get reference to main scene from boss
	main_scene = boss.main_scene
	
	# Start moving down
	var camera = boss.get_viewport().get_camera_2d()
	if camera:
		var screen_size = boss.get_viewport().get_visible_rect().size
		var camera_bottom = camera.global_position.y + screen_size.y / 2
		target_y = camera_bottom + sprite_height
		boss.global_position.y = target_y
	start_moving_down()

func exit() -> void:
	is_moving_down = false
	is_moving_back = false
	
	# Reset health when exiting waiting state
	if boss and boss.HealthController:
		boss.HealthController.current_health = boss.HealthController.max_health
		boss.HealthController.has_died = false
		boss.HealthController.health_changed.emit(boss.HealthController.current_health)
		if boss.HealthController.has_method("update_hp_label"):
			boss.HealthController.update_hp_label()

func physics_update(delta: float) -> void:
	if not boss:
		return
	
	boss.currentSpeed = boss.speedManager.update(delta)
	
	if is_moving_back:
		handle_moving_back(delta)

func start_moving_down():
	is_moving_down = true
	boss.is_hiding = true
	boss.is_positioned = false
	slide_timer = 0.0
	
	# Calculate target position (one screen height below camera, accounting for sprite height)
	var camera = boss.get_viewport().get_camera_2d()
	if camera:
		var screen_size = boss.get_viewport().get_visible_rect().size
		var camera_bottom = camera.global_position.y + screen_size.y / 2
		target_y = camera_bottom + sprite_height
	
	# Clear current obstacle state
	boss.current_obstacle = null
	boss.escape_direction = 0
	boss.direction = 0
	
	# Disable raycasts
	if boss.ray_cast_left:
		boss.ray_cast_left.enabled = false
	if boss.ray_cast_right:
		boss.ray_cast_right.enabled = false
	if boss.ray_cast_center:
		boss.ray_cast_center.enabled = false

func handle_moving_back(delta: float):
	# Interpolate from current position back to original position over slide_back_duration
	slide_timer += delta
	
	if slide_timer >= slide_back_duration:
		# Slide back complete - position back to original, accounting for sprite_height
		boss.global_position.y = original_position.y
		is_moving_back = false
		boss.is_positioned = true
		boss.is_hiding = false
		
		# Re-enable raycasts
		if boss.ray_cast_left:
			boss.ray_cast_left.enabled = true
		if boss.ray_cast_right:
			boss.ray_cast_right.enabled = true
		if boss.ray_cast_center:
			boss.ray_cast_center.enabled = true
		
		# Transition back to driving state
		finished.emit(DRIVING)
	else:
		# Smooth interpolation from current down position back to original position
		var progress = slide_timer / slide_back_duration
		boss.global_position.y = lerp(boss.global_position.y, original_position.y, progress)
	
	boss.velocity = Vector2.ZERO
	boss.move_and_slide()


func _on_waiting_timer_timeout() -> void:
	print("moving backkkkk")
	is_moving_back = true
