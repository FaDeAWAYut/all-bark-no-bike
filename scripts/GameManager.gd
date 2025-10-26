extends Node

class_name GameManager

signal game_started
signal game_ended
signal hp_changed(new_hp)

var playerHp : int = 100
var isGameOver : bool = false

func start_new_game():
	playerHp = 100
	isGameOver = false
	game_started.emit()

func reduce_HP(hp : int):
	if isGameOver:
		return
		
	playerHp = max(0, playerHp - hp)
	hp_changed.emit(playerHp)
	
	if playerHp <= 0:
		end_game()

func end_game():
	isGameOver = true
	game_ended.emit()
