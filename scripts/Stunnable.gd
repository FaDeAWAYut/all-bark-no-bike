class_name Stunnable extends CharacterBody2D

var _is_stunned: bool = false

# Only parent node can set the stunned state
func _set_stunned(value: bool, caller: Node) -> void:
	if caller == get_parent():
		_is_stunned = value

# Public function for parent to set stunned to true
func set_stunned() -> void:
	_set_stunned(true, get_parent())

# Public function for parent to set stunned to false
func clear_stunned() -> void:
	_set_stunned(false, get_parent())

func is_stunned() -> bool:
	return _is_stunned
