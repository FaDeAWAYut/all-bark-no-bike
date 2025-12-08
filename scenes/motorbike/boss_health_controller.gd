extends Node

@export var max_health: int = 100
@export var phase_two_max_health: int = 100
@export var current_health: int
@onready var health_bar: Node = $"../HealthBar"
var hud: Node
@export_group("Throwing Level Changes")
@export var hp_percent_to_change: float = 0.0
@export var new_throw_level: int = 2
var is_throw_level_changed = false

@export_group("Volume Settings")
var hurtSounds: Array = [
	preload("res://assets/sfx/smalldamage1.mp3"),
	preload("res://assets/sfx/smalldamage2.mp3"),
	preload("res://assets/sfx/smalldamage3.mp3")
]
@export var hurt_volume_db: float = -5.0

# NEW: Big damage sound for charge bark
var big_damage_sound: AudioStream = preload("res://assets/sfx/bigdamage.mp3")
@export var big_damage_volume_db: float = -5.0  # Volume for big damage sound

var bikerSounds: Array = [
	preload("res://assets/sfx/biker1.mp3"),
	preload("res://assets/sfx/biker2.mp3"),
	preload("res://assets/sfx/biker3.mp3"),
	preload("res://assets/sfx/biker4.mp3"),
]

var sound_thresholds: Array[Dictionary] = [
	{"threshold": 1500, "sound_index": 1, "played": false},
	{"threshold": 1000, "sound_index": 2, "played": false},
	{"threshold": 500,  "sound_index": 3, "played": false},
]
var max_health_sound_played: bool = false

@export var biker_volume_db: float = 5.0

var small_impact_scene = preload("res://scenes/impact/small_impact.tscn")
var big_impact_scene = preload("res://scenes/impact/big_impact.tscn")  # Big impact for charge bark
@export_group("impact offsets")
@export var small_impact_offset = -50
@export var big_impact_offset = -150

signal health_changed(new_health: int)
signal died

var motorbike: Motorbike
var is_phase_two: bool = false

@onready var isPhaseOne = get_parent().get_parent().name == "Phase1"

func _ready():
	# Get reference to motorbike and determine phase
	motorbike = get_parent() as Motorbike
	# Phase 2 status provided by motorbike
	is_phase_two = motorbike != null and !(isPhaseOne)
	
	# Use appropriate max health based on phase
	if is_phase_two:
		current_health = phase_two_max_health
	else:
		current_health = max_health
	update_hp_label()

# UPDATED: Add bark_type parameter to distinguish between normal and charge bark
func take_damage(damage_amount: int, impact_position: Vector2 = Vector2.ZERO, bark_type: String = "normal"):
	# Store old health for threshold checking
	var old_health = current_health
	
	# Prevent damage while stunned
	if motorbike and motorbike.state_machine.state.name == "Stunned":
		return
	
	current_health = max(0, current_health - damage_amount)
	health_changed.emit(current_health)
	update_hp_label()
	
	# NEW: Play biker sound based on threshold crossings
	play_biker_sound_by_threshold(old_health, current_health)
	
	# UPDATED: Play different sound based on bark type
	if bark_type == "charge":
		play_big_damage_sound()
	else:
		play_random_hurt_sound()
	
	# Create impact effect at the hit position
	if impact_position != Vector2.ZERO:
		# Choose impact effect based on bark type
		if bark_type == "charge":
			spawn_big_impact_effect(impact_position)
		else:
			spawn_small_impact_effect(impact_position)
	
	# Trigger motorbike visual effects
	if get_parent() and get_parent().has_method("trigger_hit_effects"):
		get_parent().trigger_hit_effects()

	if current_health <= 0:
		# Phase 2: Transition to stunned state instead of dying immediately
		if is_phase_two and motorbike:
			motorbike.state_machine._transition_to_next_state("Stunned")
		else:
			died.emit()

	if !is_throw_level_changed:
		if float(current_health)/float(max_health) <= hp_percent_to_change:
			$"..".throwing_level = new_throw_level
			is_throw_level_changed = true

func restore_health(heal_amount: int):
	var current_max = phase_two_max_health if is_phase_two else max_health
	current_health = min(current_max, current_health + heal_amount)
	health_changed.emit(current_health)
	update_hp_label()

func update_hp_label():
	if isPhaseOne and hud:
		hud.get_node("TextureProgressBarBoss").value = current_health
	elif !isPhaseOne and health_bar:
		health_bar.value = current_health


func play_random_hurt_sound():
	if hurtSounds.is_empty():
		push_warning("No hurt sounds loaded!")
		return
	
	# Select random sound from the array
	var random_index = randi() % hurtSounds.size()
	var selected_sound = hurtSounds[random_index]
	
	# Create one-shot audio player
	var sound_player = AudioStreamPlayer.new()
	sound_player.stream = selected_sound
	sound_player.volume_db = hurt_volume_db
	
	# Auto-delete when finished
	sound_player.finished.connect(sound_player.queue_free)
	
	get_tree().current_scene.add_child(sound_player)
	sound_player.play()

# NEW: Play big damage sound for charge bark
func play_big_damage_sound():
	if big_damage_sound == null:
		push_warning("No big damage sound loaded!")
		return
	
	# Create one-shot audio player for big damage
	var sound_player = AudioStreamPlayer.new()
	sound_player.stream = big_damage_sound
	sound_player.volume_db = big_damage_volume_db
	
	# Auto-delete when finished
	sound_player.finished.connect(sound_player.queue_free)
	
	get_tree().current_scene.add_child(sound_player)
	sound_player.play()
	
func spawn_small_impact_effect(position: Vector2):
	if small_impact_scene:
		var impact = small_impact_scene.instantiate()
		impact.global_position = position + Vector2(0,small_impact_offset) # + some offset
		get_tree().current_scene.add_child(impact)

# NEW: Spawn big impact effect for charge bark
func spawn_big_impact_effect(position: Vector2):
	if big_impact_scene:
		var impact = big_impact_scene.instantiate()
		impact.global_position = position + Vector2(0,big_impact_offset) # + some offset
		get_tree().current_scene.add_child(impact)

func play_biker_sound_by_threshold(old_health: int, new_health: int):
	# Check if we just crossed below max health for the first time
	if not max_health_sound_played and new_health < old_health:
		var max_hp = phase_two_max_health if is_phase_two else max_health
		if old_health == max_hp and new_health < max_hp:
			play_specific_biker_sound(0)  # "เห้ย อะไรวะ"
			max_health_sound_played = true
	
	# Check all other thresholds
	for threshold_data in sound_thresholds:
		if not threshold_data["played"]:
			# Check if we crossed the threshold from above
			if old_health > threshold_data["threshold"] and new_health <= threshold_data["threshold"]:
				play_specific_biker_sound(threshold_data["sound_index"])
				threshold_data["played"] = true

# Helper function to play a specific biker sound
func play_specific_biker_sound(sound_index: int):
	if sound_index < 0 or sound_index >= bikerSounds.size():
		push_warning("Invalid biker sound index: ", sound_index)
		return
	
	var selected_sound = bikerSounds[sound_index]
	var sound_player = AudioStreamPlayer.new()
	sound_player.stream = selected_sound
	sound_player.volume_db = 5.0
	sound_player.finished.connect(sound_player.queue_free)
	get_tree().current_scene.add_child(sound_player)
	sound_player.play()
	
