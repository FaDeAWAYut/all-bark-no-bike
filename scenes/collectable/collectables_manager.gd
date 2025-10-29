extends Node

class_name CollectablesManager

@export_group("Cough Drops")
@export var cough_drop_pool: Pool
@export var cough_drop_spawn_interval: float = 2.0
var cough_drop_timer: float = 0.0

@export_group("Other Drops")
# reference to other pools here

func update(delta: float, camera_y_position: float, screen_size_x: float):
	cough_drop_timer += delta
	
	if cough_drop_timer >= cough_drop_spawn_interval:
		spawn_cough_drops(camera_y_position, screen_size_x)
		cough_drop_timer = 0.0

func spawn_cough_drops(camera_y_position: float, screen_size_x: float):
	var cough_drop = cough_drop_pool.get_object()
	var drop_y_level = camera_y_position - 1500
	var drop_x_level = screen_size_x * randf_range(0.3, 0.7)
	cough_drop.position = Vector2(drop_x_level, drop_y_level)

func cleanup_offscreen_collectables(camera_y_position: float, screen_size_y: float):
	var collectables_to_remove = []
	
	for collectable in cough_drop_pool.active_objects:
		if collectable.position.y > (camera_y_position + screen_size_y):
			collectables_to_remove.append(collectable)
	
	for collectable in collectables_to_remove:
		collectable.return_to_pool()
