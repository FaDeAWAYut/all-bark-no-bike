extends Panel

@onready var useTouchscreen = DisplayServer.is_touchscreen_available()

@onready var shoot_label : Label = $KeybindContainer/ShootLabel
@onready var shoot_button : Button = $KeybindContainer/ShootButton

var current_button : Button
var move_keys = ["Up", "Down", "Left", "Right", "W", "A", "S", "D"]

func _ready() -> void:	
	if useTouchscreen:
		$Keybind.visible = false
		$KeybindContainer.visible = false
		get_parent().size.y = 190
		get_parent().position.y = 200
		
	_update_labels() # called to refresh the labels
	
# Whenever a button is pressed, do:
func _on_button_pressed(button_name: String) -> void:
	current_button = $KeybindContainer.get_node(button_name)
	current_button.text = "Press key"

func _input(event: InputEvent) -> void:
	
	if !current_button: # return if current_button is null
		return
		
	if event is InputEventKey:
		if event.as_text_key_label() in move_keys:
			shoot_button.text = "No move keys!"
			await get_tree().create_timer(1).timeout
			_update_labels()
			return
		
		# Erase the event in the Input map
		InputMap.action_erase_events("shoot")

		# And assign the new event to it
		InputMap.action_add_event("shoot", event)
		
		_update_labels() # refresh the labels
		
		# After a key is assigned, set current_button back to null
		current_button = null
		
func _update_labels() -> void:
	var eb1 : Array[InputEvent] = InputMap.action_get_events("shoot")
	if eb1.size() > 0:
		var key_text = eb1[0].as_text()
		if key_text == "Space (Physical)" || key_text == "Space":
			shoot_button.text = "Spacebar"
		else:
			shoot_button.text = key_text
	else:
		shoot_button.text = "Unassigned"
