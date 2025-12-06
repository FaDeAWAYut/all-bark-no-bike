extends Node

class_name CollectablesManager

@export var spawn_offset_y: float = 1000.0

@export_group("Cough Drops")
@export var cough_drop_pool: Pool
@export var upgrade_pool_1: Pool
@export var upgrade_pool_2: Pool
@export var min_spawn_interval: float = 1.0
@export var max_spawn_interval: float = 5.0
@export var upgrade_spawn_chance: float = 0.3
@export var cough_drop_scale: float = 2
@export var collectable_speed_multiplier: float = 0.8

@export var gameManager: GameManager

var cough_drop_speed: float = 0.0
var cough_drop_timer: float = 0.0
var current_spawn_interval: float

var spawning_enabled: bool = true
var cleared_signal_emitted: bool = false

signal collectables_cleared

func update(delta: float, camera_y_position: float, screen_size_x: float, current_speed: float):
	move_drop(delta)
	
	if not spawning_enabled:
		return
		
	if current_spawn_interval == 0.0:
		current_spawn_interval = randf_range(min_spawn_interval, max_spawn_interval)
	
	cough_drop_timer += delta
	cough_drop_speed = current_speed * collectable_speed_multiplier

	if cough_drop_timer >= current_spawn_interval:
		spawn_cough_drops(camera_y_position, screen_size_x)
		cough_drop_timer = 0.0
		current_spawn_interval = randf_range(min_spawn_interval, max_spawn_interval)

func move_drop(delta: float):
	if cough_drop_pool and cough_drop_pool.active_objects:
		for drop in cough_drop_pool.active_objects:
			if is_instance_valid(drop):
				drop.position.y += cough_drop_speed * delta
	
	if upgrade_pool_1:
		for upgrade in upgrade_pool_1.active_objects:
			if is_instance_valid(upgrade):
				upgrade.position.y += cough_drop_speed * delta
				
	if upgrade_pool_2:
		for upgrade in upgrade_pool_2.active_objects:
			if is_instance_valid(upgrade):
				upgrade.position.y += cough_drop_speed * delta
				
func spawn_cough_drops(camera_y_position: float, screen_size_x: float):
	var drop_y_level = camera_y_position - spawn_offset_y 
	var drop_x_level = screen_size_x * randf_range(0.3, 0.7)
	var random_value = randf()
	
	if random_value < upgrade_spawn_chance and upgrade_pool_1 and upgrade_pool_2:
		# Spawn bone
		var upgrade = upgrade_pool_1.get_object() if randf() > 0.5 else upgrade_pool_2.get_object()
		upgrade.position = Vector2(drop_x_level, drop_y_level)
		upgrade.scale = Vector2(1.5, 1.5)
		
		if upgrade.has_signal("coughdrop_collected") and not upgrade.coughdrop_collected.is_connected(_on_cough_drop_collected):
				upgrade.coughdrop_collected.connect(_on_cough_drop_collected)
			
	else:
		# Spawn cough drop (more frequent)
		if cough_drop_pool:
			var cough_drop = cough_drop_pool.get_object()
			cough_drop.position = Vector2(drop_x_level, drop_y_level)
			cough_drop.scale = Vector2(cough_drop_scale, cough_drop_scale)
			
			# Connect signal if not already connected
			if cough_drop.has_signal("coughdrop_collected") and not cough_drop.coughdrop_collected.is_connected(_on_cough_drop_collected):
				cough_drop.coughdrop_collected.connect(_on_cough_drop_collected)

# NEW: Handle cough drop collection using your existing signal
func _on_cough_drop_collected(collectable):
	# Check what type was collected
	if collectable.collectable_type == "coughdrop":
		if gameManager and gameManager.has_method("add_charge"):
			gameManager.add_charge(1)
	elif collectable.collectable_type == "health":
		gameManager.add_health(10)
	elif collectable.collectable_type == "shield":
		gameManager.use_shield(10.0)

func stop_spawning():
	spawning_enabled = false
	cleared_signal_emitted = false  
	check_and_emit_cleared()

func start_spawning():
	spawning_enabled = true
	cleared_signal_emitted = false 
	cough_drop_timer = 0.0
	current_spawn_interval = 0.0

func cleanup_offscreen_collectables(camera_y_position: float, screen_size_y: float):
	var collectables_to_remove = []
	
	for collectable in cough_drop_pool.active_objects:
		if collectable.position.y > (camera_y_position + screen_size_y):
			collectables_to_remove.append(collectable)
	
	for collectable in collectables_to_remove:
		collectable.return_to_pool()
	
	var upgrades_to_remove = []
	for collectable in upgrade_pool_1.active_objects:
		if collectable.position.y > (camera_y_position + screen_size_y):
			upgrades_to_remove.append(collectable)
	
	for collectable in upgrade_pool_2.active_objects:
		if collectable.position.y > (camera_y_position + screen_size_y):
			upgrades_to_remove.append(collectable)
	
	for collectable in upgrades_to_remove:
		collectable.return_to_pool()
			
	if not spawning_enabled:
		check_and_emit_cleared()

func check_and_emit_cleared():
	if cleared_signal_emitted:
		return
		
	var all_pools_empty = true
	
	if cough_drop_pool and cough_drop_pool.active_objects.size() > 0:
		all_pools_empty = false
	
	if upgrade_pool_1 and upgrade_pool_1.active_objects.size() > 0:
		all_pools_empty = false

	if upgrade_pool_2 and upgrade_pool_2.active_objects.size() > 0:
		all_pools_empty = false
	
	if all_pools_empty:
		cleared_signal_emitted = true
		collectables_cleared.emit()
