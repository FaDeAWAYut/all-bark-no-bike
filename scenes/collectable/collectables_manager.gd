extends Node

class_name CollectablesManager

@export_group("Cough Drops")
@export var cough_drop_pool: Pool
@export var min_spawn_interval: float = 1.0
@export var max_spawn_interval: float = 5.0
@export var cough_drop_scale: float = 0.2
var cough_drop_timer: float = 0.0
var current_spawn_interval: float

var spawning_enabled: bool = true

signal collectables_cleared

@export_group("Other Drops")
# reference to other pools here

func update(delta: float, camera_y_position: float, screen_size_x: float):
	if not spawning_enabled:
		return
		
	if current_spawn_interval == 0.0:
		current_spawn_interval = randf_range(min_spawn_interval, max_spawn_interval)
	
	cough_drop_timer += delta
	
	if cough_drop_timer >= current_spawn_interval:
		spawn_cough_drops(camera_y_position, screen_size_x)
		cough_drop_timer = 0.0
		current_spawn_interval = randf_range(min_spawn_interval, max_spawn_interval)

func spawn_cough_drops(camera_y_position: float, screen_size_x: float):
	var cough_drop = cough_drop_pool.get_object()
	var drop_y_level = camera_y_position - 1500
	var drop_x_level = screen_size_x * randf_range(0.3, 0.7)
	cough_drop.position = Vector2(drop_x_level, drop_y_level)
	cough_drop.scale = Vector2(cough_drop_scale, cough_drop_scale)

func stop_spawning():
	spawning_enabled = false
	
	# Check if all pools are empty and emit signal if so
	check_and_emit_cleared()

func cleanup_offscreen_collectables(camera_y_position: float, screen_size_y: float):
	var collectables_to_remove = []
	
	for collectable in cough_drop_pool.active_objects:
		if collectable.position.y > (camera_y_position + screen_size_y):
			collectables_to_remove.append(collectable)
	
	for collectable in collectables_to_remove:
		collectable.return_to_pool()
	
	# Check if pools are empty after cleanup (only if spawning is disabled)
	if not spawning_enabled:
		check_and_emit_cleared()

func check_and_emit_cleared():
	# Check if all pools have no active items
	var all_pools_empty = true
	
	# Check cough drop pool
	if cough_drop_pool and cough_drop_pool.active_objects.size() > 0:
		all_pools_empty = false
	
	# Add checks for other pools here when they're added
	# if other_pool and other_pool.active_objects.size() > 0:
	#     all_pools_empty = false
	
	if all_pools_empty:
		print("All collectables cleared")
		collectables_cleared.emit()
