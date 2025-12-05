extends MotorbikeFriendState

# Movement timer variables
var timer: float = 0.0
var change_direction_time: float = 2.0
var obstacle_timer: float = 0.0

func enter(_previous_state_path: String, _data := {}) -> void:
	# Initialize driving state
	timer = 0.0
	change_direction_time = randf_range(0.5, 1.5)
	obstacle_timer = 0.0
	
	# Set initial direction
	boss.direction = 0

func physics_update(delta: float) -> void:
	if not boss:
		return
		
	# Only handle driving behavior if motorbike is positioned and not hiding/showing
	if not boss.is_positioned or boss.is_hiding or boss.is_showing:
		return
		
	timer += delta
	obstacle_timer += delta
	
	boss.currentSpeed = boss.speedManager.update(delta)
	
	# Handle rotation based on direction
	boss.rotation = lerp_angle(boss.rotation, boss.direction_rotation_angle * boss.direction, delta * boss.direction_rotation_speed)
	
	# Check for obstacles periodically
	if obstacle_timer >= boss.obstacle_check_rate:
		check_for_obstacles()
		obstacle_timer = 0.0
	
	# Handle movement based on obstacle presence
	if boss.current_obstacle:
		handle_obstacle_escape()
	else:
		handle_normal_movement()

	enforce_boundaries()
	boss.move_and_slide()

func handle_normal_movement():
	# Change direction when timer reaches threshold
	if timer >= change_direction_time:
		change_direction()
		timer = 0.0
		change_direction_time = randf_range(0.5, 1.5)
	
	# Move only horizontally (no vertical movement since camera is static)
	boss.velocity.x = boss.direction * boss.speed_x
	boss.velocity.y = 0  # No vertical movement

func handle_obstacle_escape():
	# Move away from obstacle (only horizontally)
	boss.direction = boss.escape_direction
	boss.velocity.x = boss.escape_direction * boss.escape_speed
	boss.velocity.y = 0  # No vertical movement

func check_for_obstacles():
	boss.current_obstacle = null
	boss.escape_direction = 0
	
	# Check all raycasts for obstacles
	var obstacles = []
	
	if boss.ray_cast_center and boss.ray_cast_center.is_colliding():
		var obstacle = boss.ray_cast_center.get_collider()
		if obstacle and obstacle != boss:
			obstacles.append(obstacle)
			# Determine escape direction based on obstacle position
			var obstacle_pos = boss.ray_cast_center.get_collision_point()
			boss.escape_direction = 1 if obstacle_pos.x < boss.global_position.x else -1
	
	# Check side raycasts for better decision making
	if boss.ray_cast_left and boss.ray_cast_left.is_colliding():
		var obstacle = boss.ray_cast_left.get_collider()
		if obstacle and obstacle != boss:
			obstacles.append(obstacle)
			boss.escape_direction = 1  # Move right if obstacle on left
	
	if boss.ray_cast_right and boss.ray_cast_right.is_colliding():
		var obstacle = boss.ray_cast_right.get_collider()
		if obstacle and obstacle != boss:
			obstacles.append(obstacle)
			boss.escape_direction = -1  # Move left if obstacle on right
	
	# If we found obstacles, set current obstacle
	if obstacles.size() > 0:
		boss.current_obstacle = obstacles[0]
		# If we haven't determined escape direction, choose randomly
		if boss.escape_direction == 0:
			boss.escape_direction = 1 if randf() > 0.5 else -1

func change_direction():
	var random_number = randf()
	if random_number <= 0.33:
		boss.direction = 1
	elif random_number <= 0.66:
		boss.direction = -1
	else:
		boss.direction = 0

func enforce_boundaries():
	# Horizontal boundaries
	if boss.global_position.x <= boss.min_x:
		boss.global_position.x = boss.min_x
		if boss.direction == -1:
			boss.direction = 1
		if boss.escape_direction == -1:
			boss.escape_direction = 1
	elif boss.global_position.x >= boss.max_x:
		boss.global_position.x = boss.max_x
		if boss.direction == 1:
			boss.direction = -1
		if boss.escape_direction == 1:
			boss.escape_direction = -1
	
	# Vertical boundaries (keep within top half of screen)
	if boss.global_position.y <= boss.screen_top_y:
		boss.global_position.y = boss.screen_top_y
	elif boss.global_position.y >= boss.screen_bottom_y:
		boss.global_position.y = boss.screen_bottom_y
