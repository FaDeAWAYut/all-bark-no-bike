extends Node

# Preload the obstacle scenes
var carScene = preload("res://scenes/car/car.tscn")

# Module instances
var gameManager: GameManager
var obstacleSpawner: ObstacleSpawner
var speedManager: SpeedManager

# Game constants
const dogStartPosition := Vector2i(960, 920)
const camStartPosition := Vector2i(960, 560)

var screenSize : Vector2i

func _ready():
	screenSize = get_window().size
	initialize_modules()
	setup_signal_connections()
	new_game()

func initialize_modules():
	# Create and setup game manager
	gameManager = GameManager.new()
	add_child(gameManager)
	
	# Create and setup obstacle spawner
	obstacleSpawner = ObstacleSpawner.new()
	obstacleSpawner.setup(1.0, -0.5, 5.0)
	obstacleSpawner.add_obstacle_scene(carScene)
	add_child(obstacleSpawner)
	
	# Create and setup speed manager
	speedManager = SpeedManager.new()
	speedManager.startSpeed = 5.0
	speedManager.maxSpeed = 100
	add_child(speedManager)

func setup_signal_connections():
	# Connect game manager signals
	gameManager.hp_changed.connect(_on_hp_changed)
	gameManager.game_ended.connect(_on_game_ended)
	
	# Connect obstacle spawner signals
	obstacleSpawner.obstacle_spawned.connect(_on_obstacle_spawned)
	
	# Connect speed manager signals
	speedManager.speed_changed.connect(_on_speed_changed)

func new_game():
	gameManager.start_new_game()
	speedManager.start()
	
	$"TheDawg".position = dogStartPosition
	$"TheDawg".velocity = Vector2i(0, 0)
	$Camera2D.position = camStartPosition

func _process(delta):
	if gameManager.isGameOver:
		return
		
	var currentSpeed = speedManager.update(delta)
	
	# Update obstacle spawning
	obstacleSpawner.update(delta, $Camera2D.position.y, screenSize.x)
	obstacleSpawner.cleanup_offscreen_obstacles($Camera2D.position.y, screenSize.y)
	
	show_hp()
	
	# Move the dawg and the cam
	$"TheDawg".position.y -= currentSpeed
	$Camera2D.position.y -= currentSpeed

func _on_obstacle_spawned(obs: Node):
	# Add the obstacle to the scene and set up collision
	add_child(obs)
	obstacleSpawner.add_obstacle(obs, _on_obstacle_collision)

func _on_obstacle_collision(body):
	if body.name == "TheDawg":
		gameManager.reduce_HP(10)

func show_hp():
	$HUD.get_node("HPLabel").text = "HP: " + str(gameManager.playerHp)

func _on_hp_changed(new_hp: int):
	show_hp()

func _on_game_ended():
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = true

func _on_speed_changed(new_speed: float):
	# Handle speed change events if needed
	pass
