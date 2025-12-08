extends Node2D

# References to imported nodes
@onready var parallax_bg = $ParallaxBG
@onready var animation_player = $AnimationPlayer
@onready var camera = $Camera2D

# Background music
var transition_music = preload("res://assets/sfx/NoBikeEndRiff_Piano.mp3")
var music_player: AudioStreamPlayer

func _ready():
	# Stop all movement
	setup_static_scene()
	
	# Play transition music
	play_transition_music()
	
	# Start the transition animation
	start_transition_animation()

func setup_static_scene():

	# Stop background scrolling
	if parallax_bg is ParallaxBackground:
		parallax_bg.scroll_base_offset = Vector2.ZERO

func play_transition_music():
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	music_player.volume_db = -5.0
	music_player.stream = transition_music
	music_player.autoplay = true
	music_player.finished.connect(music_player.play)
	add_child(music_player)

func start_transition_animation():
	animation_player.play("ending_animation")
