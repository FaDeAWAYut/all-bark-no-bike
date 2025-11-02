extends Node

class_name ObstacleSpawner

signal obstacle_spawned(new_obstacle)
signal obstacles_cleared

# Pool-based obstacle management
@export var obstacle_pools: Array[Pool] = []
@export var spawn_offset_y: float = 1000.0
var obstacleTimer : float = 0.0
var obstacleSpawnInterval : float = 2.0
var minSpawnVariation : float = -0.5
var maxSpawnVariation : float = 5.0

# Lane settings - 4 lanes, each 64 pixels wide
var lane_width: float = 64.0*2
var num_lanes: int = 4
var lane_positions: Array = []

# Add obstacle movement settings
var obstacleSpeed: float = 0.0
var spawning_enabled: bool = true

func _ready():
	pass

func setup(spawn_interval: float, min_variation: float, max_variation: float, screen_size_x: float):
	obstacleSpawnInterval = spawn_interval
	minSpawnVariation = min_variation
	maxSpawnVariation = max_variation
	calculate_lane_positions(screen_size_x)

func calculate_lane_positions(screen_size_x: float):
	# Clear previous positions
	lane_positions.clear()
	
	# Calculate the total width occupied by all lanes
	var total_lanes_width = num_lanes * lane_width
	
	# Calculate starting position to center the lanes on screen
	var start_x = (screen_size_x - total_lanes_width) / 2
	
	# Calculate the center of each lane
	for i in range(num_lanes):
		var lane_center = start_x + (i * lane_width) + (lane_width / 2)
		lane_positions.append(lane_center)
		
func add_obstacle_pool(pool: Pool):
	if not obstacle_pools.has(pool):
		obstacle_pools.append(pool)

func stop_spawning():
	spawning_enabled = false
	check_and_emit_cleared()

func start_spawning():
	spawning_enabled = true
	# Reset timer to start spawning immediately or after a fresh interval
	obstacleTimer = 0.0

func update(delta: float, camera_y_position: float, screen_size_x: float, current_speed: float):
	obstacleSpeed = current_speed  # Update obstacle speed
	
	# Calculate lane positions if not done yet or if screen size changed
	if lane_positions.is_empty():
		calculate_lane_positions(screen_size_x)
		
	# Always update obstacles (movement and cleanup), regardless of spawning state
	update_obstacles(delta, camera_y_position, screen_size_x)
	
	# Only spawn new obstacles if spawning is enabled
	if not spawning_enabled:
		return
		
	obstacleTimer += delta
	
	var current_interval = obstacleSpawnInterval + randf_range(minSpawnVariation, maxSpawnVariation)
	
	if obstacleTimer >= current_interval:
		try_spawn_obstacle(camera_y_position, screen_size_x)
		obstacleTimer = 0.0

func update_obstacles(_delta: float, camera_y_position: float, _screen_size_x: float):
	# Create a list to track obstacles that need to be returned to pool
	var obstacles_to_remove = []
	
	for pool in obstacle_pools:
		# Create a copy of active_objects to avoid modification during iteration
		var active_obstacles = pool.active_objects.duplicate()
		for obs in active_obstacles:
			if is_instance_valid(obs):
				# Set speed for obstacle movement
				if obs.has_method("set_speed"):
					obs.set_speed(obstacleSpeed)
				
				# Check if offscreen manually if check_offscreen method doesn't exist or isn't working
				var screen_size_y = get_viewport().get_visible_rect().size.y
				if obs.position.y > (camera_y_position + screen_size_y + 200):  
					obstacles_to_remove.append(obs)
	
	# Return offscreen obstacles to pool
	for obs in obstacles_to_remove:
		if obs.has_method("return_to_pool"):
			obs.return_to_pool()
	
	# Check if obstacles are cleared after cleanup (only if spawning is disabled)
	if not spawning_enabled:
		check_and_emit_cleared()

func try_spawn_obstacle(camera_y_position: float, screen_size_x: float):
	if obstacle_pools.is_empty():
		return
	
	# Recalculate lane positions if screen size might have changed
	if lane_positions.is_empty():
		calculate_lane_positions(screen_size_x)

	# Pick a random pool to spawn from
	var pool = obstacle_pools[randi() % obstacle_pools.size()]
	var obs = pool.get_object()
	
	# Spawn just above the top of the screen
	var spawnY = camera_y_position - spawn_offset_y
	# Pick a random lane for spawning
	var random_lane = randi() % num_lanes
	var spawnX = lane_positions[random_lane]
	
	obs.position = Vector2(spawnX, spawnY)
	
	# Set initial speed
	if obs.has_method("set_speed"):
		obs.set_speed(obstacleSpeed)
	
	obstacle_spawned.emit(obs)

func check_and_emit_cleared():
	# Check if all pools have no active obstacles
	var all_pools_empty = true
	
	for pool in obstacle_pools:
		if pool and pool.active_objects.size() > 0:
			all_pools_empty = false
			break
	
	if all_pools_empty:
		obstacles_cleared.emit()

func get_total_active_obstacles() -> int:
	var total = 0
	for pool in obstacle_pools:
		total += pool.active_objects.size()
	return total
