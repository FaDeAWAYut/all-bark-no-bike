class_name Stunnable extends Node

var _is_stunned: bool = false

# only stunnable or extending classes can set this
func _set_stunned(value: bool, caller: Node) -> void:
	if caller is Stunnable:
		_is_stunned = value

# Public functions
func set_stunned() -> void:
	_set_stunned(true, self)

func clear_stunned() -> void:
	_set_stunned(false, self)

func is_stunned() -> bool:
	return _is_stunned
