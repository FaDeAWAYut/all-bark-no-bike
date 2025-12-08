extends Control

@onready var high_score_label = $HighScore
var high_score = 0
@onready var menu_music = preload("res://assets/sfx/AllBarkNoBikeMenu.mp3")
var music_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false # unpause from gameover
	play_menu_music()
	load_high_score()

func _input(event):
	# Check if our custom action was pressed
	if event.is_action_pressed("reset_high_score"):
		reset_high_score()

func play_menu_music():
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	music_player.stream = menu_music
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

func load_high_score():
	var save_path = "user://score.save"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		high_score = file.get_var()
		high_score_label.text = "High score: %d" % [high_score]

func reset_high_score():
	high_score = 0
	high_score_label.text = "0"
	
	# Save to file
	var save_path = "user://score.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(0)
	file.close()
	load_high_score()
