extends MotorbikeFriendState

# zooming variables
var vertical_speed = -200
var zooming_done = false

func enter(_previous_state_path: String, _data := {}) -> void:
	# Start going forward when entering turning state
	zooming_done = false
	start_zooming()

func physics_update(_delta: float) -> void:
	if !zooming_done:
		handle_zooming()
	else:
		handle_end_zooming()

	boss.move_and_slide()

func exit() -> void:
	# Clean up any zooming-specific state
	pass

func start_zooming():
	boss.velocity.x = 0
	boss.velocity.y = vertical_speed
	boss.escape_direction = 0
	boss.direction = 0

func handle_zooming():
	var camera = boss.get_viewport().get_camera_2d()
	if camera:
		var screen_size = boss.get_viewport().get_visible_rect().size
		var camera_top = camera.global_position.y - screen_size.y / 2
		var camera_bottom = camera.global_position.y + screen_size.y / 2
		
		# If bike is above the camera viewport, emit signal and hide
		if boss.global_position.y < camera_top - 100:
			boss.global_position.y = camera_bottom + 200
			zooming_done = true

func handle_end_zooming():
	var camera = boss.get_viewport().get_camera_2d()
	if camera:
		var screen_size = boss.get_viewport().get_visible_rect().size
		var camera_bottom = camera.global_position.y + screen_size.y / 2 + 10
		
		# If bike is above the camera viewport, emit signal and hide
		if boss.global_position.y <= camera_bottom:
			boss.velocity.y = 0
			finished.emit(DRIVING)
