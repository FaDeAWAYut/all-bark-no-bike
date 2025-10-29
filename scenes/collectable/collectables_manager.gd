extends Node

@export var cough_drop_pool: Pool

func _ready():
	spawn_cough_drops(0.0, 1152.0)

# reference to other drops

func spawn_cough_drops(camera_y_position: float, screen_size_x: float):
    var cough_drop = cough_drop_pool.get_object()
    var drop_y_level = camera_y_position - 1500
    var drop_x_level = screen_size_x * randf_range(0.3, 0.7)
    cough_drop.position = Vector2(drop_x_level, drop_y_level)

