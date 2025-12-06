extends MotorbikeFriendState

var is_hiding: bool = false
var is_showing: bool = false

func enter(_previous_state_path: String, _data := {}) -> void:
	# Start hiding when entering turning state
	start_hiding()

func exit() -> void:
	# Clean up any turning-specific state
	is_hiding = false
	is_showing = false

func physics_update(delta: float) -> void:
	if not boss:
		return
	
	boss.currentSpeed = boss.speedManager.update(delta)
	
	if is_hiding:
		handle_hiding(delta)
	elif is_showing:
		handle_showing(delta)

func start_hiding():
	if boss.is_hidden:
		return

	if not boss.is_positioned:
		return

	is_hiding = true
	boss.is_hiding = true
	boss.is_positioned = false
	
	# Clear current obstacle state - these are used by the driving state
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

func handle_hiding(_delta: float):
	# Use increased velocity to speed up the bike when hiding
	boss.velocity.x = 0  # Stop horizontal movement
	boss.velocity.y = -1 * boss.currentSpeed * boss.hide_speed_multiplier
	
	# Check if bike is outside camera viewport
	var camera = boss.get_viewport().get_camera_2d()
	if camera:
		var screen_size = boss.get_viewport().get_visible_rect().size
		var camera_top = camera.global_position.y - screen_size.y / 2
		
		# If bike is above the camera viewport, emit signal and hide
		if boss.global_position.y < camera_top - 100:  # Add 100px buffer
			boss.hide()
			boss.motorbike_hidden.emit()
			is_hiding = false
			boss.is_hiding = false
			boss.is_hidden = true
	boss.move_and_slide()

# Public method that can be called from external scripts
func start_showing():
	if not boss or not boss.is_hidden:
		return

	# Re-enable raycasts
	if boss.ray_cast_left:
		boss.ray_cast_left.enabled = true
	if boss.ray_cast_right:
		boss.ray_cast_right.enabled = true
	if boss.ray_cast_center:
		boss.ray_cast_center.enabled = true

	var screen_size = boss.get_viewport().get_visible_rect().size
	var camera = boss.get_viewport().get_camera_2d()
	# Position at top of camera viewport + screen height above
	var camera_top = camera.global_position.y - screen_size.y / 2
	var target = camera_top - screen_size.y  # This puts it one screen height above the top

	boss.global_position = Vector2(boss.global_position.x, target)
	boss.direction = 0
	boss.show()
	is_showing = true
	boss.is_showing = true

func handle_showing(_delta: float):
	boss.velocity.x = 0  # Stop horizontal movement while showing
	boss.velocity.y = boss.currentSpeed * boss.hide_speed_multiplier
	
	var camera = boss.get_viewport().get_camera_2d()
	if camera:
		var target_y = camera.global_position.y + boss.offset_from_camera.y
		if boss.global_position.y >= target_y:
			boss.global_position.y = target_y
			is_showing = false
			boss.is_showing = false
			boss.is_hidden = false
			boss.is_positioned = true
			# Transition back to driving state
			finished.emit(DRIVING)
	boss.move_and_slide()
