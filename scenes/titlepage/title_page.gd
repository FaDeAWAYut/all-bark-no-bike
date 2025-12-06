extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false # unpause from gameover


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/level_1_intro.tscn")


func _on_level_1_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/level_1_intro.tscn")


func _on_level_2_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/transistion_phase.tscn")
