extends Node

# Preload the obstacle scenes
var carScene = preload("res://scenes/car/car.tscn")

# Module instances
var gameManager: GameManager
var obstacleSpawner: ObstacleSpawner
var speedManager: SpeedManager
var barkController: BarkController
var screenEffects: ScreenEffects

@export var collectablesManager: CollectablesManager

# Game constants
@export var dogStartPosition := Vector2i(960, 920)
@export var camStartPosition := Vector2i(960, 560)
var canChargeShoot: bool = true
@export var currentSpeed: float

@export var car_obstacle_scale: float = 0.5

# Background scrolling settings
@export var startingBackgroundSpeed: float = 1000.0  # Starting scroll speed
@export var maxBackgroundSpeed: float = 1500.0  # Maximum scroll speed
@export var timeToMaxSpeed: float = 30.0       # Time in seconds to reach max speed
var backgroundScrollSpeed: float = 0.0
var totalBackgroundOffset: float = 0.0
var gameTime: float = 0.0

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
	add_child(speedManager)
	
	# Create and setup bark controller
	barkController = BarkController.new()
	barkController.setup($"TheDawg")
	add_child(barkController)
	
	# Create and setup screen effects
	screenEffects = ScreenEffects.new()
	screenEffects.setup($Camera2D, screenSize, self)
	add_child(screenEffects)

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
	
	# Reset background scrolling
	totalBackgroundOffset = 0.0
	backgroundScrollSpeed = 0.0
	gameTime = 0.0
	reset_background_position()

func _physics_process(delta: float):
	if gameManager.isGameOver:
		return
		
	currentSpeed = speedManager.update(delta)
	gameTime += delta
	
	# Update obstacle spawning
	# obstacleSpawner.update(delta, $Camera2D.position.y, screenSize.x, currentSpeed)
	# obstacleSpawner.cleanup_offscreen_obstacles($Camera2D.position.y, screenSize.y)
	
	#update item drop spawning
	collectablesManager.update(delta, $Camera2D.position.y, screenSize.x, currentSpeed)
	collectablesManager.cleanup_offscreen_collectables($Camera2D.position.y, screenSize.y)
	show_hp()

	# Update screen effects
	screenEffects.update_screen_shake(delta)
	
	# Scroll the background instead of moving camera
	scroll_background(delta)

func scroll_background(delta: float):
	if has_node("ParallaxBackground"):
		var parallax = $ParallaxBackground
		
		# Calculate current background speed with acceleration
		var targetSpeed = calculate_background_speed()
		backgroundScrollSpeed = targetSpeed * delta
		totalBackgroundOffset += backgroundScrollSpeed
		
		# Apply scrolling to the parallax background (single layer)
		# If you have ParallaxLayer children, use this:
		for child in parallax.get_children():
			if child is ParallaxLayer:
				child.motion_offset.y += backgroundScrollSpeed
				
				# Reset offset when it exceeds mirroring distance to create seamless loop
				var mirror_y = child.motion_mirroring.y
				if mirror_y > 0 and child.motion_offset.y >= mirror_y:
					child.motion_offset.y = 0
		
		# If your ParallaxBackground doesn't have layers and scrolls directly, use this:
		# parallax.scroll_offset.y += backgroundScrollSpeed

func calculate_background_speed() -> float:
	# Calculate speed based on game time, accelerating from start to max speed
	if timeToMaxSpeed <= 0:
		return maxBackgroundSpeed
	
	# Linear interpolation from startingBackgroundSpeed to maxBackgroundSpeed
	var progress = min(gameTime / timeToMaxSpeed, 1.0)
	return lerp(startingBackgroundSpeed, maxBackgroundSpeed, progress)

func reset_background_position():
	if has_node("ParallaxBackground"):
		var parallax = $ParallaxBackground
		for child in parallax.get_children():
			if child is ParallaxLayer:
				child.motion_offset.y = 0

func _on_obstacle_spawned(obs: Node):
	# Add the obstacle to the scene and set up collision
	add_child(obs)
	obs.scale = Vector2(car_obstacle_scale, car_obstacle_scale)
	obstacleSpawner.add_obstacle(obs, _on_obstacle_collision)

func _on_obstacle_collision(body):
	if body.name == "TheDawg":
		gameManager.reduce_HP(10)

func show_hp():
	$HUD.get_node("HPLabel").text = "HP: " + str(gameManager.playerHp)

func _on_hp_changed(new_hp: int):
	show_hp()
	
func _input(event):
	if gameManager.isGameOver:
		return
		
	if event.is_action_pressed("shoot") and canChargeShoot:
		barkController.shoot_chargebark()
		screenEffects.screen_shake(0.1, 0.2)
		screenEffects.screen_flash(0.3, 0.15)

func _on_game_ended():
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = true

func _on_speed_changed(new_speed: float):
	# Handle speed change events if needed
	pass
