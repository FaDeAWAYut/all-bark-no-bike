extends Node

# Preload the obstacle scenes
var carScenes = [preload("res://scenes/car/black_car.tscn"), preload("res://scenes/car/mini_car.tscn"),preload("res://scenes/car/truck_car.tscn")]

# Module instances
var gameManager: GameManager
@export var obstacleSpawner: ObstacleSpawner
var speedManager: SpeedManager
@export var barkController: BarkController
var screenEffects: ScreenEffects

@export var collectablesManager: CollectablesManager

# Game constants
@export var dogStartPosition := Vector2i(960, 920)
@export var camStartPosition := Vector2i(960, 560)
var canChargeShoot: bool = true
@export var currentSpeed: float

@export var car_obstacle_scale: float = 1

# Background scrolling settings
var gameTime: float = 0.0

var screenSize : Vector2i

var hurtSFX = preload("res://assets/sfx/hurtsfx.mp3")

var bgMusic = preload("res://assets/sfx/wipwipwip2.mp3")

@export var hurtSoundVolume = -5
@export var bgMusicVolume = -5

@onready var parallax = $ParallaxBG/Parallax2D

func _ready():
	screenSize = get_window().size
	initialize_modules()
	setup_signal_connections()
	new_game()
	play_background_music()

func initialize_modules():
	gameManager = GameManager.new()
	add_child(gameManager)

	# Create car pool and add to obstacle spawner FIRST
	var car_pool = Pool.new()
	add_child(car_pool)  # Add to scene tree FIRST

	# NOW assign the object_scenes
	car_pool.object_scenes = carScenes
	car_pool.pool_size = 10
	car_pool.initialize()

	# Create and setup obstacle spawner
	obstacleSpawner.setup(1.0, -0.5, 5.0, screenSize.x)
	add_child(obstacleSpawner)

	# Add the already initialized car pool to obstacle spawner
	obstacleSpawner.add_obstacle_pool(car_pool)

	# Create and setup speed manager
	speedManager = SpeedManager.new()
	add_child(speedManager)
	
	# Create and setup screen effects
	screenEffects = ScreenEffects.new()
	screenEffects.setup($Camera2D, screenSize, self)
	add_child(screenEffects)
	
	var cough_drop_scenes = [preload("res://scenes/collectable/cough_drop.tscn")]  # Add your actual scene path
	var cough_drop_pool = Pool.new()
	add_child(cough_drop_pool)
	cough_drop_pool.object_scenes = cough_drop_scenes
	cough_drop_pool.pool_size = 5  # Adjust as needed
	cough_drop_pool.initialize()
	
	# Initialize normal bark pool for BarkController
	var normal_bark_scenes = [preload("res://scenes/normalbark/normalbark.tscn")]  # Replace with your actual scene path
	var normal_bark_pool = Pool.new()
	add_child(normal_bark_pool)
	normal_bark_pool.object_scenes = normal_bark_scenes
	normal_bark_pool.pool_size = 5  # Adjust based on how many barks you want available
	normal_bark_pool.initialize()
	barkController.normal_bark_pool = normal_bark_pool
	
	# Assign to collectables manager
	collectablesManager.cough_drop_pool = cough_drop_pool


func setup_signal_connections():
	# Connect game manager signals
	gameManager.game_ended.connect(_on_game_ended)
	gameManager.hp_changed.connect(_on_hp_changed)
	
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
	gameTime = 0.0

func _physics_process(delta: float):
	if gameManager.isGameOver:
		return
		
	currentSpeed = speedManager.update(delta)
	gameTime += delta
	
	# Update obstacle spawning
	obstacleSpawner.update(delta, $Camera2D.position.y, screenSize.x, currentSpeed)
	
	#update item drop spawning
	collectablesManager.update(delta, $Camera2D.position.y, screenSize.x, currentSpeed)
	collectablesManager.cleanup_offscreen_collectables($Camera2D.position.y, screenSize.y)
	
	show_hp()

	# Update screen effects
	screenEffects.update_screen_shake(delta)
	
	# Scroll the background instead of moving camera
	scroll_background(delta)

func scroll_background(delta: float):
	#var targetSpeed = calculate_background_speed()
	# TODO: add more Parallax2D nodes for more layers? may not be necessary
	parallax.autoscroll.y = currentSpeed
		
func _on_obstacle_spawned(obs: Node):
	# Set up obstacle collision and scaling (obstacle is already managed by pool)
	obs.scale = Vector2(car_obstacle_scale, car_obstacle_scale)
	
	# Connect collision signal if the obstacle has it
	if obs.has_signal("body_entered"):
		obs.body_entered.connect(_on_obstacle_collision)

func _on_obstacle_collision(body):
	if body.name == "TheDawg":
		gameManager.reduce_HP(5)
		screenEffects.screen_shake(5, 0.4)
		screenEffects.screen_damage_flash(0.2, 0.8)
		play_hurt_sound()
		
func play_hurt_sound():
	var soundPlayer = AudioStreamPlayer.new()
	soundPlayer.stream = hurtSFX
	soundPlayer.volume_db = hurtSoundVolume
	
	soundPlayer.finished.connect(soundPlayer.queue_free)
	
	add_child(soundPlayer)
	soundPlayer.play()
	
func play_background_music():
	var music_player = AudioStreamPlayer.new()
	music_player.stream = bgMusic
	music_player.volume_db = bgMusicVolume
	music_player.autoplay = true
	music_player.name = "BackgroundMusic"
	
	# Make it loop
	music_player.finished.connect(music_player.play)
	
	add_child(music_player)
	 
func _input(event):
	if gameManager.isGameOver:
		return
		
	if event.is_action_pressed("shoot"):
		barkController.shoot_normalbark()
		#screenEffects.screen_shake(0.1, 0.2)
		#screenEffects.screen_flash(0.3, 0.15)
func show_hp():
	$HUD.get_node("TextureProgressBar").value = gameManager.playerHp

func _on_hp_changed(new_hp: int):
	show_hp() 

func _on_game_ended():
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = true

func _on_speed_changed(new_speed: float):
	# Handle speed change events if needed
	pass
