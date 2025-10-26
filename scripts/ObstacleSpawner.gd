extends Node

class_name ObstacleSpawner

signal obstacle_spawned(new_obstacle)
signal obstacle_despawned(obstacle)

var obstacleArray := []
var obstacles : Array
var lastObstacle
var obstacleTimer : float = 0.0
var obstacleSpawnInterval : float = 1.0
var minSpawnVariation : float = -0.5
var maxSpawnVariation : float = 5.0

func _ready():
	pass

func setup(spawn_interval: float, min_variation: float, max_variation: float):
	obstacleSpawnInterval = spawn_interval
	minSpawnVariation = min_variation
	maxSpawnVariation = max_variation

func add_obstacle_scene(scene: PackedScene):
	if not obstacleArray.has(scene):
		obstacleArray.append(scene)

func update(delta: float, camera_y_position: float, screen_size_x: float):
	obstacleTimer += delta
	
	var current_interval = obstacleSpawnInterval + randf_range(minSpawnVariation, maxSpawnVariation)
	
	if obstacles.is_empty() or (obstacleTimer >= current_interval):
		try_spawn_obstacle(camera_y_position, screen_size_x)
		obstacleTimer = 0.0

func try_spawn_obstacle(camera_y_position: float, screen_size_x: float):
	if obstacleArray.is_empty():
		return
		
	var obsType = obstacleArray[randi() % obstacleArray.size()]
	var obs = obsType.instantiate()
	
	var obsYLevel = camera_y_position - 1500
	var obsXLevel = screen_size_x * randf_range(0.3, 0.7)
	
	obs.position = Vector2(obsXLevel, obsYLevel)
	obstacle_spawned.emit(obs)

func add_obstacle(obs, collision_handler: Callable):
	obstacles.append(obs)
	lastObstacle = obs
	
	# Connect collision signal if the obstacle has it
	if obs.has_signal("body_entered"):
		obs.body_entered.connect(collision_handler)

func remove_obs(obs):
	if obstacles.has(obs):
		obstacles.erase(obs)
		obstacle_despawned.emit(obs)
	
	if is_instance_valid(obs):
		obs.queue_free()

func cleanup_offscreen_obstacles(camera_y_position: float, screen_size_y: float):
	var obstacles_to_remove = []
	
	for obs in obstacles:
		if obs.position.y > (camera_y_position + screen_size_y):
			obstacles_to_remove.append(obs)
	
	for obs in obstacles_to_remove:
		remove_obs(obs)
