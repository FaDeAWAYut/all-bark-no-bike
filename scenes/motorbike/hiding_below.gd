extends BossState

@export var sprite_height: float = 200.0
@export var slide_down_duration: float = 1.0
@export var slide_back_duration: float = 1.0

var is_moving_down: bool = false
var is_moving_back: bool = false
var original_position: Vector2
var slide_timer: float = 0.0
var target_y: float = 0.0

func enter(_previous_state_path: String, _data := {}) -> void:
	# Start moving down when entering hiding_below state
	start_moving_down()

func exit() -> void:
	is_moving_down = false
	is_moving_back = false

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
	original_position = boss.global_position
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
		# If bike is below the camera viewport, emit signal and hide
		var camera = boss.get_viewport().get_camera_2d()
		if camera:
			var screen_size = boss.get_viewport().get_visible_rect().size
			var camera_bottom = camera.global_position.y + screen_size.y / 2
			if boss.global_position.y > camera_bottom + 100:  # Add 100px buffer
				boss.hide()
				boss.motorbike_hidden.emit()
				boss.is_hidden = true
	else:
		# Smooth interpolation
		var progress = slide_timer / slide_down_duration
		boss.global_position.y = lerp(original_position.y, target_y, progress)
	
	boss.velocity = Vector2.ZERO
	boss.move_and_slide()

# Public method that can be called from external scripts
func start_showing():
	if not boss or not boss.is_hidden:
		return
	
	# Show the bike before starting to move back
	boss.show()
	
	# Re-enable raycasts
	if boss.ray_cast_left:
		boss.ray_cast_left.enabled = true
	if boss.ray_cast_right:
		boss.ray_cast_right.enabled = true
	if boss.ray_cast_center:
		boss.ray_cast_center.enabled = true

	is_moving_back = true
	slide_timer = 0.0
	boss.direction = 0

func handle_moving_back(delta: float):
	# Interpolate from current position back to original position over slide_back_duration
	slide_timer += delta
	
	if slide_timer >= slide_back_duration:
		# Slide back complete
		boss.global_position.y = original_position.y
		is_moving_back = false
		boss.is_positioned = true
		boss.is_hidden = false
		# Transition back to driving state
		finished.emit(DRIVING)
	else:
		# Smooth interpolation
		var progress = slide_timer / slide_back_duration
		boss.global_position.y = lerp(target_y, original_position.y, progress)
	
	boss.velocity = Vector2.ZERO
	boss.move_and_slide()
