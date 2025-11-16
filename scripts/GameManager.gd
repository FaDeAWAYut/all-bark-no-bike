extends Node

class_name GameManager

signal game_started
signal game_ended
signal hp_changed(new_hp)
signal charge_changed(current_charge, max_charge)
signal shield_changed(has_shield)

var playerHp : int = 100
var isGameOver : bool = false

var currentCharge: int = 0
var maxCharge: int = 3
var chargePercentage: float = 0.0

var has_shield: bool = false
var shield_timer: Timer

func start_new_game():
	playerHp = 100
	isGameOver = false
	currentCharge = 0  # RESET: Reset charges on new game
	chargePercentage = 0.0
	has_shield = false
	game_started.emit()
	charge_changed.emit(currentCharge, maxCharge)  # EMIT: Signal charge change
	shield_changed.emit(has_shield)

func _ready():
	# NEW: Create shield timer
	shield_timer = Timer.new()
	shield_timer.one_shot = true
	shield_timer.timeout.connect(_on_shield_timeout)
	add_child(shield_timer)
	
func reduce_HP(hp : int):
	if isGameOver:
		return
		
	if has_shield:
		return
		
	playerHp = max(0, playerHp - hp)
	#ส่ง signal ชื่อ hp_changed ออกไป โดยตัวแปร = playerHp
	hp_changed.emit(playerHp)
	
	if playerHp <= 0:
		end_game()

func add_health(hp: int):
	if isGameOver:
		return
		
	playerHp = min(100, playerHp + hp)
	hp_changed.emit(playerHp)

func use_shield(duration: float):
	if isGameOver:
		return false
	
	has_shield = true
	shield_timer.start(duration)
	shield_changed.emit(has_shield)
	return true

func _on_shield_timeout():
	has_shield = false
	shield_changed.emit(has_shield)

func has_active_shield() -> bool:
	return has_shield

func get_shield_time_remaining() -> float:
	return shield_timer.time_left if shield_timer else 0.0

func add_charge(amount: int = 1):
	if isGameOver:
		return
	
	currentCharge = min(currentCharge + amount, maxCharge)
	chargePercentage = float(currentCharge) / float(maxCharge) * 100.0
	charge_changed.emit(currentCharge, maxCharge)
	
func use_charge(amount: int = 1):
	if currentCharge >= amount:
		currentCharge -= amount
		chargePercentage = float(currentCharge) / float(maxCharge) * 100.0
		charge_changed.emit(currentCharge, maxCharge)
		return true
	return false

func get_charge_percentage() -> float:
	return chargePercentage

func has_full_charge() -> bool:
	return currentCharge >= maxCharge

func end_game():
	isGameOver = true
	game_ended.emit()
	
func _on_boss_died():
	get_tree().change_scene_to_file("res://scenes/main/phase2.tscn")
	
