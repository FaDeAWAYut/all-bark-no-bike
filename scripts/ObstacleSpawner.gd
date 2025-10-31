extends Node

class_name ObstacleSpawner

signal obstacle_spawned(new_obstacle)
signal obstacles_cleared

# Pool-based obstacle management
@export var obstacle_pools: Array[Pool] = []
var obstacleTimer : float = 0.0
var obstacleSpawnInterval : float = 2.0
var minSpawnVariation : float = -0.5
var maxSpawnVariation : float = 5.0

# Add obstacle movement settings
var obstacleSpeed: float = 0.0
var spawning_enabled: bool = true

func _ready():
	pass

func setup(spawn_interval: float, min_variation: float, max_variation: float):
	obstacleSpawnInterval = spawn_interval
	minSpawnVariation = min_variation
	maxSpawnVariation = max_variation

func add_obstacle_pool(pool: Pool):
	if not obstacle_pools.has(pool):
		obstacle_pools.append(pool)

func stop_spawning():
	print("Stopping obstacle spawning")
	spawning_enabled = false
	check_and_emit_cleared()

func start_spawning():
	print("Starting obstacle spawning")
	spawning_enabled = true
	# Reset timer to start spawning immediately or after a fresh interval
	obstacleTimer = 0.0

func update(delta: float, camera_y_position: float, screen_size_x: float, current_speed: float):
	if not spawning_enabled:
		return
		
	obstacleTimer += delta
	obstacleSpeed = current_speed  # Update obstacle speed
	
	var current_interval = obstacleSpawnInterval + randf_range(minSpawnVariation, maxSpawnVariation)
	
	if obstacleTimer >= current_interval:
		try_spawn_obstacle(camera_y_position, screen_size_x)
		obstacleTimer = 0.0
	
	# Update obstacles with current speed and check for offscreen
	update_obstacles(delta, camera_y_position, screen_size_x)

func update_obstacles(_delta: float, camera_y_position: float, screen_size_x: float):
	for pool in obstacle_pools:
		for obs in pool.active_objects:
			if is_instance_valid(obs):
				# Set speed for obstacle movement
				if obs.has_method("set_speed"):
					obs.set_speed(obstacleSpeed)
				
				# Check if offscreen and return to pool
				if obs.has_method("check_offscreen"):
					obs.check_offscreen(camera_y_position, screen_size_x)
	
	# Check if obstacles are cleared after cleanup (only if spawning is disabled)
	if not spawning_enabled:
		check_and_emit_cleared()

func try_spawn_obstacle(camera_y_position: float, screen_size_x: float):
	if obstacle_pools.is_empty():
		return
	
	# Pick a random pool to spawn from
	var pool = obstacle_pools[randi() % obstacle_pools.size()]
	var obs = pool.get_object()
	
	# Spawn just above the top of the screen
	var spawnY = camera_y_position - 2000  # 2000 pixels above camera
	var spawnX = screen_size_x * randf_range(0.3, 0.7)
	
	obs.position = Vector2(spawnX, spawnY)
	
	# Set initial speed
	if obs.has_method("set_speed"):
		obs.set_speed(obstacleSpeed)
	
	obstacle_spawned.emit(obs)

func cleanup_offscreen_obstacles(_camera_y_position: float, _screen_size_y: float):
	# This is now handled in update_obstacles through check_offscreen
	pass

func check_and_emit_cleared():
	# Check if all pools have no active obstacles
	var all_pools_empty = true
	
	for pool in obstacle_pools:
		if pool and pool.active_objects.size() > 0:
			all_pools_empty = false
			break
	
	if all_pools_empty:
		print("All obstacles cleared")
		obstacles_cleared.emit()

func get_total_active_obstacles() -> int:
	var total = 0
	for pool in obstacle_pools:
		total += pool.active_objects.size()
	return total
