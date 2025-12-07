extends Node

# Preload the obstacle scenes
var carScenes = [preload("res://scenes/car/black_car.tscn"), preload("res://scenes/car/mini_car.tscn"),preload("res://scenes/car/truck_car.tscn")]
var sideScenes = [preload("res://scenes/sideobstacles/meow.tscn"), preload("res://scenes/sideobstacles/banner.tscn"), preload("res://scenes/sideobstacles/bonsai.tscn")]
var chadchartWalkout = preload("res://scenes/collectable/chadchart_walkout.tscn").instantiate()

# Module instances
var gameManager: GameManager
@export var obstacleSpawner: ObstacleSpawner
@export var collectablesManager: CollectablesManager
@onready var speedManager: SpeedManager = $SpeedManager
@export var barkController: BarkController
var screenEffects: ScreenEffects

#@onready var music_player = $BgmPlayer
@export var music_player: AudioStreamPlayer
@onready var chadchartSfxPlayer: AudioStreamPlayer
#@onready var BGM_BUS_ID = AudioServer.get_bus_index("BGM") # for when we implement volume settings

@onready var isPhaseOne = self.name == "Phase1"

# Game constants
@export var dogStartPosition := Vector2i(960, 920)
@export var camStartPosition := Vector2i(960, 560)
var canChargeShoot: bool = true
@export var currentSpeed: float
@export var backgroundSpeed: float = 0.0

@export var car_obstacle_scale: float = 1
@export var side_obstacle_scale: float = 1.5

@export var dogInvincibleDuration: float = 2.0
var invincibleTimer: Timer = Timer.new()
@export var dogIsInvincible: bool = false

# Background scrolling settings
var gameTime: float = 0.0

var score = 0
var high_score = 0
var base_score_phase1 = 2000
var base_score_phase2 = 2000
var save_path = "user://score.save"

@export var timeLimit: float = 134.0 #2.14 minutes

@export var screenSize : Vector2i = Vector2(896, 512)

var hurtSFX = preload("res://assets/sfx/hurtsfx.mp3")
var shieldSFX = preload("res://assets/sfx/shieldmonk.mp3")
var healingSFX = preload("res://assets/sfx/healingsfx.mp3")
var chadchartAppearsSFX = preload("res://assets/sfx/ChadChartAppears.mp3")
var chadchartActiveSFX = preload("res://assets/sfx/ChadChartIsHere.mp3")

signal player_took_damage

var AllBarkMusic = preload("res://assets/sfx/AllBark.mp3")
var NoBikeMusic = preload("res://assets/sfx/NoBike_LongerTail.mp3")

# Timer settings
var minutes: int = 0
var seconds: int = 0

var coughDropSounds: Array = [
	preload("res://assets/sfx/cough_drop_eating1.mp3"),
	preload("res://assets/sfx/cough_drop_eating2.mp3"),
	preload("res://assets/sfx/cough_drop_eating3.mp3")
]

@export var hurtSoundVolume = -5
@export var bgmVolume = -5
@export var coughDropVolume: float = -5.0
@export var shieldSoundVolume: float = -5.0
@export var healingSoundVolume: float = -5.0 
@export var chadchartAppearsSoundVolume: float = 0.0
@export var chadchartActiveSoundVolume: float = -5.0

@export_category("Debug Options")
@export var SkipPhaseOne := false
@export var NoDamage := false

@onready var parallax = $ParallaxBG/Parallax2D
@onready var bossHealthController = $Motorbike/BossHealthController
@onready var objective_panel = $ObjectivePanel

var previousHP: int = 100

func _ready():
	get_tree().paused = false # unpause from gameover
	initialize_modules()
	setup_signal_connections()
	new_game()
	play_background_music()
	load_score()
	
	previousHP = gameManager.playerHp
	
	# NEW: Show initial objective
	show_initial_objective()
	
	# Skip Phase One debug option
	if SkipPhaseOne:
		bossHealthController.current_health = 0
		bossHealthController.update_hp_label()
		bossHealthController.died.emit()

func initialize_modules():
	gameManager = GameManager.new()
	add_child(gameManager)
	
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	add_child(music_player)

	chadchartSfxPlayer = AudioStreamPlayer.new()
	chadchartSfxPlayer.name = "ChadchartSfxPlayer"
	add_child(chadchartSfxPlayer)
	
	# Create car pool and add to obstacle spawner FIRST
	var car_pool = Pool.new()
	add_child(car_pool)

	# NOW assign the object_scenes
	car_pool.object_scenes = carScenes
	car_pool.pool_size = 10
	car_pool.initialize()
	
	# Create and setup invincible timer
	add_child(invincibleTimer)
	invincibleTimer.timeout.connect(_on_invincible_timer_timeout)
	# Create side obstacle pool
	var side_pool = Pool.new()
	add_child(side_pool)
	side_pool.object_scenes = sideScenes
	side_pool.pool_size = 8 
	side_pool.initialize()

	# Create and setup obstacle spawner
	obstacleSpawner.setup(1.0, -0.5, 5.0, screenSize.x)
	add_child(obstacleSpawner)

	# Add the already initialized car pool/side pool to obstacle spawner
	obstacleSpawner.add_obstacle_pool(car_pool)
	obstacleSpawner.add_obstacle_pool(side_pool)

	# Create and setup screen effects
	screenEffects = ScreenEffects.new()
	screenEffects.setup($Camera2D, screenSize, self)
	add_child(screenEffects)
	screenEffects.process_mode = Node.PROCESS_MODE_ALWAYS # let screenEffects run when pause tree
	
	var cough_drop_scenes = [preload("res://scenes/collectable/cough_drop.tscn")]
	var cough_drop_pool = Pool.new()
	add_child(cough_drop_pool)
	cough_drop_pool.object_scenes = cough_drop_scenes
	cough_drop_pool.pool_size = 5
	cough_drop_pool.initialize()
	
	var upgrade_scene_1 = [preload("res://scenes/collectable/bone.tscn")]
	var upgrade_pool_1 = Pool.new()
	add_child(upgrade_pool_1)
	upgrade_pool_1.object_scenes = upgrade_scene_1
	upgrade_pool_1.pool_size = 3
	upgrade_pool_1.initialize()
	
	var upgrade_scene_2 = [preload("res://scenes/collectable/necklace_monk.tscn")]
	var upgrade_pool_2 = Pool.new()
	add_child(upgrade_pool_2)
	upgrade_pool_2.object_scenes = upgrade_scene_2
	upgrade_pool_2.pool_size = 3
	upgrade_pool_2.initialize()
	
	var chadchart_scene = [preload("res://scenes/collectable/chadchart.tscn")]
	var chadchart_pool = Pool.new()
	add_child(chadchart_pool)
	chadchart_pool.object_scenes = chadchart_scene
	chadchart_pool.pool_size = 1
	chadchart_pool.initialize()
	
	# Initialize normal bark pool for BarkController
	var normal_bark_scenes = [preload("res://scenes/normalbark/normalbark.tscn")]
	var normal_bark_pool = Pool.new()
	add_child(normal_bark_pool)
	normal_bark_pool.object_scenes = normal_bark_scenes
	normal_bark_pool.pool_size = 5
	normal_bark_pool.initialize()
	
	# Initialize charge bark pool for BarkController
	var charge_bark_scenes = [preload("res://scenes/chargebark/chargebark.tscn")]
	var charge_bark_pool = Pool.new()
	add_child(charge_bark_pool)
	charge_bark_pool.object_scenes = charge_bark_scenes
	charge_bark_pool.pool_size = 3
	charge_bark_pool.initialize()
	
	# UPDATED: Pass GameManager to BarkController
	barkController.setup($"TheDawg", gameManager)
	barkController.normal_bark_pool = normal_bark_pool
	barkController.charge_bark_pool = charge_bark_pool
	
	barkController.hud = $HUD
	#to initialize Boss health bar
	var boss_max_health = bossHealthController.phase_two_max_health if bossHealthController.is_phase_two else bossHealthController.max_health
	$HUD.get_node("TextureProgressBarBoss").max_value = boss_max_health
	$HUD.get_node("TextureProgressBarBoss").value = bossHealthController.current_health
	bossHealthController.hud = $HUD
	
	
	# NEW: Pass screenEffects to BarkController
	barkController.screenEffects = screenEffects
	
	# Assign to collectables manager
	collectablesManager.cough_drop_pool = cough_drop_pool
	collectablesManager.upgrade_pool_1 = upgrade_pool_1
	collectablesManager.upgrade_pool_2 = upgrade_pool_2
	collectablesManager.chadchart_pool = chadchart_pool
	collectablesManager.gameManager = gameManager

	# Connect existing cough drops to the collectables manager
	for cough_drop in cough_drop_pool.get_children():
		if cough_drop.has_signal("coughdrop_collected"):
			if not cough_drop.coughdrop_collected.is_connected(collectablesManager._on_cough_drop_collected):
				cough_drop.coughdrop_collected.connect(collectablesManager._on_cough_drop_collected)
	
	for upgrade in upgrade_pool_1.get_children():
		if upgrade.has_signal("coughdrop_collected") && not upgrade.coughdrop_collected.is_connected(collectablesManager._on_cough_drop_collected):
				upgrade.coughdrop_collected.connect(collectablesManager._on_cough_drop_collected)
	
	for upgrade in upgrade_pool_2.get_children():
		if upgrade.has_signal("coughdrop_collected") && not upgrade.coughdrop_collected.is_connected(collectablesManager._on_cough_drop_collected):
				upgrade.coughdrop_collected.connect(collectablesManager._on_cough_drop_collected)
	
	for chadchart in chadchart_pool.get_children():
		if chadchart.has_signal("coughdrop_collected") && not chadchart.coughdrop_collected.is_connected(collectablesManager._on_cough_drop_collected):
				chadchart.coughdrop_collected.connect(collectablesManager._on_cough_drop_collected)
		
func setup_signal_connections():
	# Connect game manager signals
	gameManager.game_ended.connect(_on_game_ended)
	gameManager.hp_changed.connect(_on_hp_changed)
	gameManager.charge_changed.connect(_on_charge_changed)
	gameManager.shield_changed.connect(_on_shield_changed)
	collectablesManager.chadchart_appears.connect(_on_chadchart_appears)
	bossHealthController.died.connect(_on_boss_died)  # Connect to local handler first
	
	# Connect obstacle spawner signals
	obstacleSpawner.obstacle_spawned.connect(_on_obstacle_spawned)
	
	# Connect speed manager signals
	speedManager.speed_changed.connect(_on_speed_changed)
	
func show_initial_objective():
	if objective_panel:
		var objective_text = "Objective: "
		
		if isPhaseOne:
			objective_text += "Take him down!"
		else:
			objective_text += "Survive the timer!"
		
		objective_panel.show_objective(objective_text, true)  # Auto-hide after duration
	else:
		push_warning("Objective panel not found!")
		
func show_objective(text: String, duration: float = 5.0):
	if objective_panel:
		objective_panel.show_objective(text, duration > 0)
		
		# Set custom duration if provided
		if duration > 0 and objective_panel.has_node("Timer"):
			objective_panel.get_node("Timer").wait_time = duration

# NEW: Update objective when phase changes (for transition)
func update_objective_for_phase_two():
	if objective_panel:
		objective_panel.show_objective("Objective: Survive the timer!", true)

func _on_boss_died():
	if isPhaseOne:
		transition_to_phase_transition()

func new_game():
	gameManager.start_new_game()
	speedManager.start()
	
	$TheDawg.position = dogStartPosition
	$TheDawg.velocity = Vector2i(0, 0)
	$Camera2D.position = camStartPosition
	
	# Reset background scrolling
	gameTime = 0.0
	# Reset previous HP
	previousHP = gameManager.playerHp
	
	show_timer()

func _physics_process(delta: float):
	if gameManager.isGameOver:
		return
		
	currentSpeed = speedManager.update(delta)
	gameTime += delta
	
	# Update obstacle spawning
	obstacleSpawner.update(delta, $Camera2D.position.y, screenSize.x, currentSpeed, parallax.autoscroll.y)
	
	#update item drop spawning
	collectablesManager.update(delta, $Camera2D.position.y, screenSize.x, currentSpeed)
	collectablesManager.cleanup_offscreen_collectables($Camera2D.position.y, screenSize.y)
	
	show_hp()
	show_timer()

	# Update screen effects
	screenEffects.update_screen_shake(delta)
	
	update_shield_blink()
	# Scroll the background instead of moving camera
	scroll_background()

func scroll_background():
	parallax.autoscroll.y = currentSpeed
		
func _on_obstacle_spawned(obs: Node):
	if obs is SidewalkObstacle:
		obs.scale = Vector2(side_obstacle_scale, side_obstacle_scale)
	# Set up obstacle collision and scaling (obstacle is already managed by pool)
	else: obs.scale = Vector2(car_obstacle_scale, car_obstacle_scale)
	
	# Connect collision signal if the obstacle has it
	if obs.has_signal("body_entered"):
		obs.body_entered.connect(_on_obstacle_collision)

func _on_obstacle_collision(body):
	if body.name == "TheDawg":
		player_take_damage()
		
func player_take_damage():
	if gameManager.has_active_shield():
		return
	if !dogIsInvincible:		
		screenEffects.screen_shake(5, 0.4)
		screenEffects.screen_damage_flash(0.2, 0.8)
		play_hurt_sound()
		dogIsInvincible = true
		$TheDawg/InvincibleAnimation.play("invincible")
		invincibleTimer.start(dogInvincibleDuration)
		# Emit player damage signal for motorbike friend
		player_took_damage.emit()

		if NoDamage:
			return
		if isPhaseOne:
			gameManager.reduce_HP(10)
		else:
			gameManager.reduce_HP(5)

func _on_invincible_timer_timeout():
	$TheDawg/InvincibleAnimation.stop()
	dogIsInvincible = false

func play_hurt_sound():
	var soundPlayer = AudioStreamPlayer.new()
	soundPlayer.stream = hurtSFX
	soundPlayer.volume_db = hurtSoundVolume
	
	soundPlayer.finished.connect(soundPlayer.queue_free)
	
	add_child(soundPlayer)
	soundPlayer.play()

func play_shield_sound():
	var soundPlayer = AudioStreamPlayer.new()
	soundPlayer.stream = shieldSFX
	soundPlayer.volume_db = shieldSoundVolume
	
	soundPlayer.finished.connect(soundPlayer.queue_free)
	
	add_child(soundPlayer)
	soundPlayer.play()

func play_hp_gain_sound():
	var soundPlayer = AudioStreamPlayer.new()
	soundPlayer.stream = healingSFX
	soundPlayer.volume_db = healingSoundVolume
	
	soundPlayer.finished.connect(soundPlayer.queue_free)
	
	add_child(soundPlayer)
	soundPlayer.play()

# use chadchartSfxPlayer so that when player collects chadchart while ChadchartAppears.mp3 is still playing, the game immediately switches to ChadchartIsHere.mp3 
# เสียงจะได้ไม่เล่นทับกัน
func play_chadchart_appears_sound():
	if chadchartSfxPlayer:
		chadchartSfxPlayer.stream = chadchartAppearsSFX
		chadchartSfxPlayer.volume_db = chadchartAppearsSoundVolume
		chadchartSfxPlayer.play()
	
func play_chadchart_active_sound():
	if chadchartSfxPlayer:
		chadchartSfxPlayer.stream = chadchartActiveSFX
		chadchartSfxPlayer.volume_db = chadchartActiveSoundVolume
		chadchartSfxPlayer.play()
	
func play_background_music():
	if isPhaseOne:
		music_player.stream = AllBarkMusic
	else:
		music_player.stream = NoBikeMusic

	music_player.volume_db = bgmVolume
	music_player.autoplay = true
	
	# Make it loop
	music_player.finished.connect(music_player.play)
	
	if isPhaseOne:
		music_player.play(0)
	else:
		music_player.play(11.1)
	 
func _input(event):
	if gameManager.isGameOver:
		return
		
	if event.is_action_pressed("shoot"):
		# Start charging when space is pressed
		barkController.start_charging()
		
	if event.is_action_released("shoot"):
		# Release charge when space is released
		barkController.release_charge()
func show_hp():
	$HUD.get_node("TextureProgressBar").value = gameManager.playerHp

func _on_hp_changed(new_hp: int):
	if new_hp >= previousHP:
		play_hp_gain_sound()
	
	previousHP = new_hp
	show_hp()

func _on_shield_changed(has_shield: bool, is_chadchart: bool):
	if has_shield:
		if is_chadchart:
			activate_chadchart()
		else: 
			play_shield_sound()	
		
	var shield_icon = $HUD.get_node("TextureRect")
	if shield_icon:
		shield_icon.visible = has_shield

func update_shield_blink():
	var shield_icon = $HUD.get_node("TextureRect")
	if not shield_icon or not gameManager.has_active_shield():
		return
	
	var time_remaining = gameManager.get_shield_time_remaining()
	
	# Start blinking when 3 seconds or less remain
	if time_remaining <= 3.0:
		shield_icon.visible = (int(Time.get_ticks_msec() * 0.005) % 2 == 0)
	else:
		shield_icon.visible = true
	
func show_charge():
	var charge_percentage = (float(gameManager.currentCharge) / float(gameManager.maxCharge)) * 100.0
	$HUD.get_node("TextureProgressBarCharge").value = charge_percentage

func _on_charge_changed(current_charge: int, max_charge: int):
	show_charge()
	
	# NEW: Play collection sound based on charge level
	play_cough_drop_sound(current_charge)

# NEW: Function to play the appropriate cough drop sound
func play_cough_drop_sound(charge_level: int):
	if charge_level < 1 or charge_level > coughDropSounds.size():
		return
	
	# Play sound corresponding to the charge level (1 = first sound, 2 = second, etc.)
	var sound_index = charge_level - 1
	if sound_index < coughDropSounds.size():
		var sound_player = AudioStreamPlayer.new()
		sound_player.stream = coughDropSounds[sound_index]
		sound_player.volume_db = coughDropVolume
		sound_player.finished.connect(sound_player.queue_free)
		add_child(sound_player)
		sound_player.play()
		
func show_timer():
	var timerPanel = $HUD.get_node("Panel")
	if isPhaseOne:
		seconds = fmod(gameTime, 60)
		minutes = fmod(gameTime, 3600) / 60
		timerPanel.get_node("SecondsLabel").text = "%02d" % seconds
		timerPanel.get_node("MinutesLabel").text = "%02d:" % minutes
	else:
		var timeLeft = max(timeLimit - gameTime, 0)
		seconds = fmod(timeLeft, 60)
		minutes = fmod(timeLeft, 3600) / 60
		timerPanel.get_node("SecondsLabel").text = "%02d" % seconds
		timerPanel.get_node("MinutesLabel").text = "%02d:" % minutes
		
		if timeLeft <= 0 and not gameManager.isGameOver:
			# Player wins the game (phase 2)
			get_tree().change_scene_to_file("res://scenes/main/ending_animation.tscn")
			
func _on_game_ended():
	calculate_score()
	# Check for high score
	if score > high_score:
		high_score = score
		save_high_score()
	
	# Display score in GameOver panel
	display_score()
	
	$GameOver.show()
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.05).timeout
	Engine.time_scale = 1.0
	get_tree().paused = true

func _on_speed_changed(new_speed: float):
	# Handle speed change events if needed
	pass
	
func transition_to_phase_transition():
	# Capture current positions and state
	# Load transition scene
	get_tree().change_scene_to_file("res://scenes/main/transition_phase.tscn")
	
func _on_chadchart_appears():
	play_chadchart_appears_sound()
	
func activate_chadchart():
	$TheDawg/AnimatedSprite2D.animation = &"chadchart_active"
	$TheDawg/AnimatedSprite2D.scale = Vector2(0.25,0.25)
	music_player.volume_db = -60.0
	play_chadchart_active_sound()
	await get_tree().create_timer(11.5).timeout
	
	# after chadchart use
	gradually_increase_bgm_volume(5)
	add_child(chadchartWalkout)
	chadchartWalkout.get_child(2).hide() # hide Control node
	chadchartWalkout.position = Vector2($TheDawg.position.x,$TheDawg.position.y)
	chadchartWalkout.get_child(0).animation = &"no_shield"
	$TheDawg/AnimatedSprite2D.animation = &"default"
	$TheDawg/AnimatedSprite2D.scale = Vector2(1,1)
	
	# delete node after ~5 secs, when chadchart has walked out of screen
	await get_tree().create_timer(5).timeout
	chadchartWalkout.queue_free() 
	
func gradually_increase_bgm_volume(duration_sec: float):
	const muteVolume = -60.0
	for i in range(1, duration_sec*10+1): # *10 for less increase in each step -> smoother increase
		await get_tree().create_timer(0.1).timeout
		music_player.volume_db = muteVolume + (bgmVolume - muteVolume) * (i/(duration_sec*10))
		
func calculate_score():
	# calculate total score after game ended
	if isPhaseOne:
		score = (base_score_phase1 - bossHealthController.current_health)*5
	else:
		var timeLeft = max(timeLimit - gameTime, 0)
		score = (base_score_phase2 - timeLeft*(base_score_phase2/timeLimit))*5
		
func display_score():
	var panel = $GameOver.get_node("Panel")
	panel.get_node("Score").text = "High Score: %d\nScore: %d" % [high_score, score]

func save_high_score():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(high_score)

func load_score():
	if FileAccess.file_exists(save_path):
		print("file found")
		var file = FileAccess.open(save_path, FileAccess.READ)
		high_score = file.get_var()
	else:
		print("file not found")
		high_score = 0
