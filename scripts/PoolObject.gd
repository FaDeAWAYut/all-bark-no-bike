extends Node2D

class_name PoolObject

var pool_ref: Pool
var is_active: bool = false

func activate():
	is_active = true
	set_process(true)
	set_physics_process(true)
	show()

func deactivate():
	is_active = false
	set_process(false)
	set_physics_process(false)
	hide()

func return_to_pool():
	if pool_ref:
		pool_ref.return_object(self)