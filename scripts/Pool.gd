extends Node

class_name Pool

@export var object_scenes: Array
@export var pool_size: int = 10
var pool: Array = []
var active_objects: Array = []
var is_initialized: bool = true

func _ready():
	pass
	
func initialize():
	if object_scenes:
		for i in pool_size:
			var random_scene = object_scenes[randi() % object_scenes.size()]
			var obj = random_scene.instantiate()
			obj.pool_ref = self
			obj.deactivate()
			add_child(obj)
			pool.append(obj)
	is_initialized = true

func get_object():
	if not is_initialized:
		initialize()
		
	var obj
	if pool.size() > 0:
		obj = pool.pop_back()
	else:
		var random_scene = object_scenes[randi() % object_scenes.size()]
		obj = random_scene.instantiate()
		obj.pool_ref = self
		add_child(obj)
	
	active_objects.append(obj)
	obj.activate()
	return obj

func return_object(obj):
	if obj in active_objects:
		active_objects.erase(obj)
		obj.deactivate()
		pool.append(obj)
