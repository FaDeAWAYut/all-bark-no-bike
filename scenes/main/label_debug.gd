extends Label

#func _process(_delta):
	#var dir = $"../Joystick".get_joystick_dir()
	#self.text = "({x}, {y})".format({"x": snapped(dir.x, 0.01), "y": snapped(dir.y, 0.01)})
