extends Node

class_name BarkController

# Reference to the dog node
@export var theDawg: Node2D

# Bark spawn offset
@export var barkSpawnOffset: Vector2 = Vector2(0, -50)

@export var normal_bark_pool: Pool	
@export var charge_bark_pool: Pool

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

# NEW: Reference to ScreenEffects
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
		else:
			# Charge is ready, keep it at 0%
			current_charge_progress = 0.0
			is_charge_ready = true
		
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

func release_charge():
	if not is_charging:
		return
		
	is_charging = false
	
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
	bullet.global_position = theDawg.global_position + barkSpawnOffset
	
	# Play charge bark sound
	play_charge_bark_sound()
	
	# NEW: Add screen shake and blue flash effect for charge bark
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
