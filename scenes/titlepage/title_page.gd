extends Control

@onready var menu_music = preload("res://assets/sfx/AllBarkNoBikeMenu.mp3")
@export var menu_music_volume_db: float = -5.0
var music_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false # unpause from gameover
	play_menu_music()

func play_menu_music():
	music_player = AudioStreamPlayer.new()
	music_player.stream = menu_music
	music_player.volume_db = menu_music_volume_db
	music_player.autoplay = true
	music_player.name = "MenuMusic"

	music_player.finished.connect(music_player.play)

	add_child(music_player)


func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/level_1_intro.tscn")

func _on_level_1_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/level_1_intro.tscn")

func _on_level_2_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/transition_phase.tscn")
