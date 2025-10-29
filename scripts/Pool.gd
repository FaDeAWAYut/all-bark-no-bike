extends Node

class_name Pool

@export var object_scene: PackedScene
@export var pool_size: int = 10
var pool: Array = []
var active_objects: Array = []

func _ready():
	if object_scene:
		for i in pool_size:
			var obj = object_scene.instantiate()
			obj.pool_ref = self
			obj.deactivate()
			add_child(obj)
			pool.append(obj)

func get_object():
	var obj
	if pool.size() > 0:
		obj = pool.pop_back()
	else:
		obj = object_scene.instantiate()
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