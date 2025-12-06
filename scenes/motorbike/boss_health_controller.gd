extends Node

@export var max_health: int = 100
@export var phase_two_max_health: int = 100
var current_health: int
var hud: Node

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
@export var biker_volume_db: float = 0

var small_impact_scene = preload("res://scenes/impact/small_impact.tscn")
var big_impact_scene = preload("res://scenes/impact/big_impact.tscn")  # Big impact for charge bark
@export_group("impact offsets")
@export var small_impact_offset = -50
@export var big_impact_offset = -150

signal health_changed(new_health: int)
signal died

var motorbike: Motorbike
var is_phase_two: bool = false

func _ready():
	# Get reference to motorbike and determine phase
	motorbike = get_parent() as Motorbike
	# Phase 2 is tied to the Phase2 scene; default to Phase 1 health otherwise
	var current_scene = get_tree().current_scene
	is_phase_two = current_scene != null and current_scene.name == "Phase2"
	
	# Use appropriate max health based on phase
	if is_phase_two:
		current_health = phase_two_max_health
	else:
		current_health = max_health
	update_hp_label()

# UPDATED: Add bark_type parameter to distinguish between normal and charge bark
func take_damage(damage_amount: int, impact_position: Vector2 = Vector2.ZERO, bark_type: String = "normal"):
	# Prevent damage while stunned
	if motorbike and motorbike.state_machine.state.name == "Stunned":
		return
	
	current_health = max(0, current_health - damage_amount)
	health_changed.emit(current_health)
	update_hp_label()
	
	play_biker_sound(current_health)
	
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

func restore_health(heal_amount: int):
	var current_max = phase_two_max_health if is_phase_two else max_health
	current_health = min(current_max, current_health + heal_amount)
	health_changed.emit(current_health)
	update_hp_label()

func update_hp_label():
	if hud:
		hud.get_node("TextureProgressBarBoss").value = current_health


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

func play_biker_sound(current_health):
	var sound_player = AudioStreamPlayer.new()
	var selected_sound
	# CAN ADJUST ACCORDING TO THE STATE MACHINE NA
	if current_health == 1990:
		selected_sound = bikerSounds[0] #เห้ย อะไรวะ
	elif current_health == 1500:
		selected_sound = bikerSounds[1] #ไอหมาส้ม หยุด
	elif current_health == 1000:
		selected_sound = bikerSounds[2] #ไอหมาเวน
	elif current_health == 500:
		selected_sound = bikerSounds[3] #เห่าเหี้ยไรนักหนา
	
	sound_player.stream = selected_sound
	sound_player.volume_db = biker_volume_db
	sound_player.finished.connect(sound_player.queue_free)
	get_tree().current_scene.add_child(sound_player)
	sound_player.play()
