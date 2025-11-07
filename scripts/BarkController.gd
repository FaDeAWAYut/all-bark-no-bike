extends Node

class_name BarkController

# Reference to the dog node
@export var theDawg: Node2D

# Bark spawn offset
@export var barkSpawnOffset: Vector2 = Vector2(0, -50)

@export var normal_bark_pool: Pool	

@export var normalBarkVolume = -5

var barkSounds: Array = [
	preload("res://assets/sfx/normalbark1.mp3"),
	preload("res://assets/sfx/normalbark2.mp3"),
	preload("res://assets/sfx/normalbark3.mp3")
]

func setup(dawgNode: Node2D):
	theDawg = dawgNode

func shoot_normalbark():
	if theDawg == null:
		push_error("TheDawg reference not set in BarkController!")
		return
		
	if normal_bark_pool == null:
		push_error("Chargebark pool not initialized!")
		return
		
	# Get chargebark from pool
	var bullet = normal_bark_pool.get_object()
	
	# Position at the dog's position with adjustable offset
	bullet.global_position = theDawg.global_position + barkSpawnOffset
	
	# Play random bark sound
	play_random_bark_sound()

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
