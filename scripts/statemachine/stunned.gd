extends BossState

var stun_duration
@export var sprite_height: float = 200.0
@export var slide_down_duration: float = 1.0
@export var slide_back_duration: float = 1.0

var is_moving_down: bool = false
var is_moving_back: bool = false
var original_position: Vector2
var slide_timer: float = 0.0
var target_y: float = 0.0

func enter(_previous_state_path: String, _data := {}) -> void:
	if not boss:
		return
	
	# Prevent re-entering stunned state if already stunned
	if _previous_state_path == "Stunned":
		return
	
	# Store original position (the position to return to after stun)
	original_position = boss.global_position
	
	# Calculate stun duration based on stun multiplier
	var stun_multiplier = boss.get_stun_multiplier()
	if stun_multiplier <= 0:
		stun_multiplier = 1  
	stun_duration = boss.base_stunned_duration * stun_multiplier
	
	# Start moving down
	start_moving_down()
	
	# Set timer for stun duration
	if boss.timer:
		boss.timer.wait_time = stun_duration
		boss.timer.one_shot = true
		boss.timer.timeout.connect(_on_stun_timer_timeout)
		boss.timer.start()

func exit() -> void:
	is_moving_down = false
	if boss and boss.timer:
		boss.timer.timeout.disconnect(_on_stun_timer_timeout)
		boss.timer.stop()

func physics_update(delta: float) -> void:
	if not boss:
		return
	
	boss.currentSpeed = boss.speedManager.update(delta)
	
	if is_moving_down:
		handle_moving_down(delta)
	elif is_moving_back:
		handle_moving_back(delta)

func start_moving_down():
	if boss.is_hidden:
		return

	if not boss.is_positioned:
		return

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

func handle_moving_down(delta: float):
	# Interpolate from current position to target position over slide_down_duration
	slide_timer += delta
	
	if slide_timer >= slide_down_duration:
		# Slide complete
		boss.global_position.y = target_y
		is_moving_down = false
		boss.is_hiding = false
	else:
		# Smooth interpolation
		var progress = slide_timer / slide_down_duration
		boss.global_position.y = lerp(original_position.y, target_y, progress)
	
	boss.velocity = Vector2.ZERO
	boss.move_and_slide()

func handle_moving_back(delta: float):
	# Interpolate from current position back to original position over slide_back_duration
	slide_timer += delta
	
	if slide_timer >= slide_back_duration:
		# Slide back complete
		boss.global_position.y = original_position.y
		is_moving_back = false
		boss.is_positioned = true
		# Transition back to driving state
		finished.emit(DRIVING)
	else:
		# Smooth interpolation
		var progress = slide_timer / slide_back_duration
		boss.global_position.y = lerp(target_y, original_position.y, progress)
	
	boss.velocity = Vector2.ZERO
	boss.move_and_slide()

func _on_stun_timer_timeout():
	if not boss:
		return
	
	# Re-enable raycasts
	if boss.ray_cast_left:
		boss.ray_cast_left.enabled = true
	if boss.ray_cast_right:
		boss.ray_cast_right.enabled = true
	if boss.ray_cast_center:
		boss.ray_cast_center.enabled = true
	
	# Reset boss health to full
	if boss.BossHealthController:
		var current_max = boss.BossHealthController.phase_two_max_health if boss.BossHealthController.is_phase_two else boss.BossHealthController.max_health
		boss.BossHealthController.current_health = current_max
		boss.BossHealthController.health_changed.emit(boss.BossHealthController.current_health)
		boss.BossHealthController.update_hp_label()
	
	# Start sliding back to original position
	is_moving_back = true
	slide_timer = 0.0
	boss.direction = 0
