extends BossState

@export var stun_duration: float = 3.0

var is_moving_down: bool = false
var original_position: Vector2

func enter(_previous_state_path: String, _data := {}) -> void:
	if not boss:
		return
	
	# Store original position
	original_position = boss.global_position
	
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

func start_moving_down():
	if boss.is_hidden:
		return

	if not boss.is_positioned:
		return

	is_moving_down = true
	boss.is_hiding = true
	boss.is_positioned = false
	
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

func handle_moving_down(_delta: float):
	# Move boss one screen height below
	boss.velocity.x = 0
	boss.velocity.y = boss.currentSpeed * boss.hide_speed_multiplier
	
	# Check if bike is outside camera viewport (below)
	var camera = boss.get_viewport().get_camera_2d()
	if camera:
		var screen_size = boss.get_viewport().get_visible_rect().size
		var camera_bottom = camera.global_position.y + screen_size.y / 2
		
		# If bike is below the camera viewport, stop moving
		if boss.global_position.y > camera_bottom + 100:  # Add 100px buffer
			is_moving_down = false
			boss.is_hiding = false
	
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
	
	# Move back to original position
	boss.global_position = original_position
	boss.direction = 0
	boss.is_positioned = true
	
	# Reset boss health to full
	if boss.BossHealthController:
		var current_max = boss.BossHealthController.phase_two_max_health if boss.BossHealthController.is_phase_two else boss.BossHealthController.max_health
		boss.BossHealthController.current_health = current_max
		boss.BossHealthController.health_changed.emit(boss.BossHealthController.current_health)
		boss.BossHealthController.update_hp_label()
	
	# Transition back to driving state
	finished.emit(DRIVING)
