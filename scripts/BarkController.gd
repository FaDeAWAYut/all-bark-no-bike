extends Node

class_name BarkController

# Reference to the dog node
var theDawg: Node2D

# Bark spawn offset
@export var barkSpawnOffset: Vector2 = Vector2(0, -50)

@export var charge_bark_pool: Pool	

# Audio
var barkSound: AudioStreamPlayer
var chargebarkSFX = preload("res://assets/sfx/chargebarksfx.mp3")

func setup(dawgNode: Node2D):
	theDawg = dawgNode
	setup_audio()

func setup_audio():
	# Create audio player for bark sounds
	barkSound = AudioStreamPlayer.new()
	barkSound.stream = chargebarkSFX
	barkSound.volume_db = -5.0  # Adjust volume as needed
	add_child(barkSound)

func shoot_chargebark():
	if theDawg == null:
		push_error("TheDawg reference not set in BarkController!")
		return
		
	if charge_bark_pool == null:
		push_error("Chargebark pool not initialized!")
		return
		
	# Get chargebark from pool
	var bullet = charge_bark_pool.get_object()
	
	# Position at the dog's position with adjustable offset
	bullet.global_position = theDawg.global_position + barkSpawnOffset
	
	# Play bark sound
	play_bark_sound()

func play_bark_sound():
	if barkSound and barkSound.stream:
		barkSound.play()
