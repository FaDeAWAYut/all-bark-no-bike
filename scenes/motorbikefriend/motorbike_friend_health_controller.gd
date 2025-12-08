extends Node

@export var max_health: int = 100
var current_health: int
var has_died: bool = false
@onready var health_bar: Node = $"../HealthBar"

var hurtSounds: Array = [
	preload("res://assets/sfx/smalldamage1.mp3"),
	preload("res://assets/sfx/smalldamage2.mp3"),
	preload("res://assets/sfx/smalldamage3.mp3")
]
@export var hurt_volume_db: float = -5.0

# NEW: Big damage sound for charge bark
var big_damage_sound: AudioStream = preload("res://assets/sfx/bigdamage.mp3")
@export var big_damage_volume_db: float = -5.0  # Volume for big damage sound

var small_impact_scene = preload("res://scenes/impact/small_impact.tscn")
var big_impact_scene = preload("res://scenes/impact/big_impact.tscn")  # Big impact for charge bark
@export_group("impact offsets")
@export var small_impact_offset = -50
@export var big_impact_offset = -150

signal health_changed(new_health: int)
signal died

func _ready():
	current_health = max_health
	has_died = false
	update_hp_label()

func take_damage(damage_amount: int, impact_position: Vector2 = Vector2.ZERO, bark_type: String = "normal"):
	# Prevent damage while stunned
	if get_parent() and get_parent().state_machine and get_parent().state_machine.state.name == "Stunned":
		return
	if get_parent() and get_parent().state_machine and get_parent().state_machine.state.name == "Waiting":
		return
	
	current_health = max(0, current_health - damage_amount)
	health_changed.emit(current_health)
	update_hp_label()

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
		if not has_died:
			has_died = true
			died.emit()
			get_parent().set_stunned()

func restore_health(heal_amount: int):
	current_health = min(max_health, current_health + heal_amount)
	health_changed.emit(current_health)
	update_hp_label()

func update_hp_label():
	if health_bar:
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
