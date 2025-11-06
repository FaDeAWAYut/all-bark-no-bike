extends Node

@export var max_health: int = 100
@export var hp_label: Label
var current_health: int

var hurtSounds: Array = [
	preload("res://assets/sfx/smalldamage1.mp3"),
	preload("res://assets/sfx/smalldamage2.mp3"),
	preload("res://assets/sfx/smalldamage3.mp3")
]
@export var hurt_volume_db: float = -5.0

signal health_changed(new_health: int)
signal died

func _ready():
	current_health = max_health
	update_hp_label()

func take_damage(damage_amount: int):
	current_health = max(0, current_health - damage_amount)
	health_changed.emit(current_health)
	update_hp_label()
	
	play_random_hurt_sound()

	if current_health <= 0:
		died.emit()

func restore_health(heal_amount: int):
	current_health = min(max_health, current_health + heal_amount)
	health_changed.emit(current_health)
	update_hp_label()

func update_hp_label():
	if hp_label:
		hp_label.text = "Boss HP: " + str(current_health)

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
