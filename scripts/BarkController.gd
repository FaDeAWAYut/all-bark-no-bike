extends Node

class_name BarkController

# Reference to the dog node
@export var theDawg: Node2D

# Bark spawn offset
@export var barkSpawnOffset: Vector2 = Vector2(0, -50)

@export var normal_bark_pool: Pool	
@export var charge_bark_pool: Pool

@export var bulletDirection = Vector2.UP

@export var NormalBarkVolume = -4

# Charge orb properties
@export var charge_orb_scene: PackedScene = preload("res://scenes/chargeorb/charge_orb.tscn")
@export var charge_orb_offset: Vector2 = Vector2(0, -50)  # Y offset from dog position
var charge_orb_instance: Node2D = null
var charge_orb_tween: Tween = null

# NEW: Charging sound properties
@export var charging_sound: AudioStream = preload("res://assets/sfx/chargingsfx.mp3")
@export var charging_sound_volume_db: float = -5.0
var charging_sound_player: AudioStreamPlayer = null

# Charging properties
var is_charging: bool = false
var charge_start_time: float = 0.0
var charge_duration: float = 1.5  # 1.5 seconds to charge from 100% to 0%
var current_charge_progress: float = 0.0  # Goes from 1.0 to 0.0 during charge
var is_charge_ready: bool = false  # Track when charge is ready to fire

# Audio properties
@export var normalBarkVolume = -5
@export var chargeBarkVolume = -5

var barkSounds: Array = [
	preload("res://assets/sfx/normalbark1.mp3"),
	preload("res://assets/sfx/normalbark2.mp3"),
	preload("res://assets/sfx/normalbark3.mp3")
]

# Charge bark sound
@export var charge_bark_sound: AudioStream

# Reference to GameManager
var gameManager: GameManager

# Reference to HUD
@onready var hud = get_tree().get_first_node_in_group("hud")

# Reference to ScreenEffects
var screenEffects: ScreenEffects

func setup(dawgNode: Node2D, game_manager: GameManager):
	theDawg = dawgNode
	gameManager = game_manager

func _process(delta: float):
	# Update charging progress if currently charging
	if is_charging:
		var elapsed_time = (Time.get_ticks_msec() - charge_start_time) / 1000.0
		
		# Only update progress for the first 1.5 seconds
		if elapsed_time <= charge_duration:
			current_charge_progress = max(0.0, 1.0 - (elapsed_time / charge_duration))
			# Update charge orb scale during charging
			update_charge_orb_scale(current_charge_progress)
		else:
			# Charge is ready, keep it at 0%
			current_charge_progress = 0.0
			is_charge_ready = true
			# Ensure orb is at full scale when ready
			if charge_orb_instance:
				charge_orb_instance.scale = Vector2.ONE
		
		# Update charge orb position to follow the dog
		update_charge_orb_position()
		
		# Update HUD charge bar to show charging progress
		update_charge_bar()

func start_charging():
	if is_charging:
		return
	
	# Check if player has full charge (3 cough drops = 100% charge bar)
	if gameManager == null:
		push_error("GameManager not set in BarkController!")
		return
		
	if not gameManager.has_full_charge():
		# Not enough charges, just shoot normal bark
		shoot_normalbark()
		return
	
	# Start charging (player has full charge)
	is_charging = true
	is_charge_ready = false  # Reset charge ready flag
	charge_start_time = Time.get_ticks_msec()
	current_charge_progress = 1.0  # Start at 100%
	
	# Create and show charge orb
	spawn_charge_orb()
	
	# NEW: Start playing charging sound
	play_charging_sound()

func release_charge():
	if not is_charging:
		return
		
	is_charging = false
	
	# NEW: Stop charging sound
	stop_charging_sound()
	
	# Remove charge orb immediately
	remove_charge_orb()
	
	# Check if charge is ready (reached 0% and player can hold indefinitely)
	if is_charge_ready:
		# Charge is ready, fire charge bark
		fire_charge_bark()
	else:
		# Released too early, fire normal bark and reset charge bar
		shoot_normalbark()
		
		# Reset charge bar to show current charges
		reset_charge_bar()
	
	current_charge_progress = 0.0
	is_charge_ready = false

func fire_charge_bark():
	if gameManager.use_charge(gameManager.maxCharge):  # Use all 3 charges
		shoot_chargebark()
		reset_charge_bar()
	else:
		# Should not happen if we checked properly
		shoot_normalbark()

# NEW: Play charging sound (looping)
func play_charging_sound():
	if charging_sound == null:
		push_warning("No charging sound loaded!")
		return
	
	# Stop any existing charging sound
	stop_charging_sound()
	
	# Create and configure audio player
	charging_sound_player = AudioStreamPlayer.new()
	charging_sound_player.stream = charging_sound
	charging_sound_player.volume_db = charging_sound_volume_db
	charging_sound_player.autoplay = true
	
	# Make it loop
	charging_sound_player.finished.connect(_on_charging_sound_finished)
	
	add_child(charging_sound_player)
	charging_sound_player.play()

# NEW: Handle charging sound loop
func _on_charging_sound_finished():
	if charging_sound_player and is_charging:
		# Restart the sound if we're still charging
		charging_sound_player.play()

# NEW: Stop charging sound
func stop_charging_sound():
	if charging_sound_player:
		charging_sound_player.finished.disconnect(_on_charging_sound_finished)
		charging_sound_player.stop()
		charging_sound_player.queue_free()
		charging_sound_player = null

# Spawn charge orb
func spawn_charge_orb():
	if charge_orb_scene == null:
		push_warning("Charge orb scene not loaded!")
		return
	
	# Remove existing orb if any
	remove_charge_orb()
	
	# Create new orb instance
	charge_orb_instance = charge_orb_scene.instantiate()
	get_tree().current_scene.add_child(charge_orb_instance)
	
	# Set initial position and scale
	update_charge_orb_position()
	charge_orb_instance.scale = Vector2.ZERO
	
	# Create tween for scale animation
	charge_orb_tween = create_tween()
	charge_orb_tween.tween_property(charge_orb_instance, "scale", Vector2.ONE, charge_duration).set_ease(Tween.EASE_OUT)

# Update charge orb position to follow the dog
func update_charge_orb_position():
	if charge_orb_instance and theDawg:
		charge_orb_instance.global_position = theDawg.global_position + charge_orb_offset

# Update charge orb scale based on charging progress
func update_charge_orb_scale(progress: float):
	if charge_orb_instance:
		# Progress goes from 1.0 to 0.0, but we want scale from 0.0 to 1.0
		var target_scale = 1.0 - progress
		charge_orb_instance.scale = Vector2(target_scale, target_scale)

# Remove charge orb
func remove_charge_orb():
	if charge_orb_instance:
		if charge_orb_tween:
			charge_orb_tween.kill()
			charge_orb_tween = null
		charge_orb_instance.queue_free()
		charge_orb_instance = null

func shoot_normalbark():
	if theDawg == null:
		push_error("TheDawg reference not set in BarkController!")
		return
		
	if normal_bark_pool == null:
		push_error("Normal bark pool not initialized!")
		return
		
	# Get normal bark from pool
	var bullet = normal_bark_pool.get_object()
	
	# Position at the dog's position with adjustable offset
	bullet.direction = bulletDirection
	bullet.global_position = theDawg.global_position + barkSpawnOffset
	
	# Play random bark sound
	play_random_bark_sound()

func shoot_chargebark():
	if theDawg == null:
		push_error("TheDawg reference not set in BarkController!")
		return
		
	if charge_bark_pool == null:
		push_error("Charge bark pool not initialized!")
		return
		
	# Get charge bark from pool
	var bullet = charge_bark_pool.get_object()
	
	# Position at the dog's position with adjustable offset
	bullet.direction = bulletDirection
	bullet.global_position = theDawg.global_position + barkSpawnOffset
	
	# Play charge bark sound
	play_charge_bark_sound()
	
	# Add screen shake and blue flash effect for charge bark
	if screenEffects:
		screenEffects.screen_shake(8.0, 0.5)  # Stronger shake for charge bark
		screenEffects.screen_charge_flash(0.1, 0.5)  # Blue flash for charge bark
	else:
		push_warning("ScreenEffects not set in BarkController!")

func play_random_bark_sound():
	if barkSounds.is_empty():
		push_warning("No bark sounds loaded!")
		return
	
	# Select random sound from the array
	var randomIndex = randi() % barkSounds.size()
	var selectedSound = barkSounds[randomIndex]
	
	# Create one-shot audio player
	var soundPlayer = AudioStreamPlayer.new()
	soundPlayer.stream = selectedSound
	soundPlayer.volume_db = normalBarkVolume
	soundPlayer.volume_db = normalBarkVolume
	
	# Auto-delete when finished
	soundPlayer.finished.connect(soundPlayer.queue_free)
	
	add_child(soundPlayer)
	soundPlayer.play()

func play_charge_bark_sound():
	if charge_bark_sound == null:
		push_warning("No charge bark sound loaded!")
		return
	
	# Create one-shot audio player for charge bark
	var soundPlayer = AudioStreamPlayer.new()
	soundPlayer.stream = charge_bark_sound
	soundPlayer.volume_db = chargeBarkVolume
	
	# Auto-delete when finished
	soundPlayer.finished.connect(soundPlayer.queue_free)
	
	add_child(soundPlayer)
	soundPlayer.play()

# Update the HUD charge bar during charging
func update_charge_bar():
	if not is_charging:
		return
		
	# Convert charge progress (1.0 to 0.0) to percentage (100 to 0)
	var charge_percentage = current_charge_progress * 100.0
	
	# Update the HUD charge bar
	update_hud_charge_bar(charge_percentage)

func reset_charge_bar():
	# Reset to show current charges (not charging progress)
	if gameManager:
		var charge_percentage = (float(gameManager.currentCharge) / float(gameManager.maxCharge)) * 100.0
		update_hud_charge_bar(charge_percentage)

func update_hud_charge_bar(percentage: float):
	# Try multiple ways to find the HUD
	if hud and hud.has_node("TextureProgressBarCharge"):
		hud.get_node("TextureProgressBarCharge").value = percentage
	else:
		# Fallback: try to find HUD again
		hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_node("TextureProgressBarCharge"):
			hud.get_node("TextureProgressBarCharge").value = percentage
		else:
			# Last resort: search by node path
			var main = get_tree().get_first_node_in_group("main")
			if main and main.has_node("HUD/TextureProgressBarCharge"):
				main.get_node("HUD/TextureProgressBarCharge").value = percentage
			elif main and main.has_node("HUD"):
				var main_hud = main.get_node("HUD")
				if main_hud.has_node("TextureProgressBarCharge"):
					main_hud.get_node("TextureProgressBarCharge").value = percentage

# Check if player can use charge bark (has full charge)
func can_use_charge_bark() -> bool:
	return gameManager != null and gameManager.has_full_charge()

# Check if currently charging and ready to fire
func is_charge_ready_to_fire() -> bool:
	return is_charging and is_charge_ready
