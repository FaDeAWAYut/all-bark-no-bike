extends Node

class_name CollectablesManager

@export var spawn_offset_y: float = 1000.0

@export_group("Cough Drops")
@export var cough_drop_pool: Pool
@export var min_spawn_interval: float = 1.0
@export var max_spawn_interval: float = 5.0
@export var cough_drop_scale: float = 0.2

var cough_drop_speed: float = 0.0
var cough_drop_timer: float = 0.0
var current_spawn_interval: float

var spawning_enabled: bool = true
var cleared_signal_emitted: bool = false

signal collectables_cleared

@export_group("Other Drops")
# reference to other pools here

func update(delta: float, camera_y_position: float, screen_size_x: float, current_speed: float):
	move_drop(delta)
	
	if not spawning_enabled:
		return
		
	if current_spawn_interval == 0.0:
		current_spawn_interval = randf_range(min_spawn_interval, max_spawn_interval)
	
	cough_drop_timer += delta
	cough_drop_speed = current_speed

	if cough_drop_timer >= current_spawn_interval:
		spawn_cough_drops(camera_y_position, screen_size_x)
		cough_drop_timer = 0.0
		current_spawn_interval = randf_range(min_spawn_interval, max_spawn_interval)

func move_drop(delta: float):
	if cough_drop_pool and cough_drop_pool.active_objects:
		for drop in cough_drop_pool.active_objects:
			if is_instance_valid(drop):
				drop.position.y += cough_drop_speed * delta

func spawn_cough_drops(camera_y_position: float, screen_size_x: float):
	var cough_drop = cough_drop_pool.get_object()
	var drop_y_level = camera_y_position - spawn_offset_y 
	var drop_x_level = screen_size_x * randf_range(0.3, 0.7)
	cough_drop.position = Vector2(drop_x_level, drop_y_level)
	cough_drop.scale = Vector2(cough_drop_scale, cough_drop_scale)

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
	
	if not spawning_enabled:
		check_and_emit_cleared()

func check_and_emit_cleared():
	if cleared_signal_emitted:
		return
		
	var all_pools_empty = true
	
	if cough_drop_pool and cough_drop_pool.active_objects.size() > 0:
		all_pools_empty = false
	
	# Add checks for other pools here when they're added
	# if other_pool and other_pool.active_objects.size() > 0:
	#     all_pools_empty = false
	if all_pools_empty:
		cleared_signal_emitted = true  # Set flag before emitting
		collectables_cleared.emit()
