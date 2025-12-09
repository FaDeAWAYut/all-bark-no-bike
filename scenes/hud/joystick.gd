extends Node2D

@onready var knob = $Knob
var max_distance = 150.0
var stick_center: Vector2
var active_touch_id: int = -1  # Track the active touch ID
var touch_position: Vector2 = Vector2.ZERO

func _ready():
	stick_center = knob.position

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and active_touch_id == -1 and event.position < Vector2(400, 400):  # Start tracking a new touch
			active_touch_id = event.index
			touch_position = event.position
		elif not event.pressed and event.index == active_touch_id: 
			active_touch_id = -1
			knob.position = stick_center  

	elif event is InputEventScreenDrag and event.index == active_touch_id:  # Update position for the active touch
		touch_position = event.position

func _process(_delta):
	if active_touch_id != -1:  
		knob.global_position = touch_position
		knob.position = stick_center + (knob.position - stick_center).limit_length(max_distance)
			

func get_joystick_dir() -> Vector2:
	var dir = knob.position - stick_center
	return dir.normalized()
