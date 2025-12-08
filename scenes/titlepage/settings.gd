extends Panel

@onready var useTouchscreen = DisplayServer.is_touchscreen_available()

@onready var shoot_label : Label = $KeybindContainer/ShootLabel
@onready var shoot_button : Button = $KeybindContainer/ShootButton
@export var bark_sound = preload("res://assets/sfx/normalbark1.mp3")

var current_button : Button
var move_keys = ["Up", "Down", "Left", "Right", "W", "A", "S", "D"]

func _ready() -> void:	
	AudioServer.set_bus_volume_db(2, -5.0) # set SFX volume
	print("setting SFX: ",AudioServer.get_bus_volume_db(2))
	if useTouchscreen:
		$Keybind.visible = false
		$KeybindContainer.visible = false
		$Audio.position.y = -19.0
		$AudioContainer.position.y = 22.0
		get_parent().size.y = 190
		get_parent().position.y = 200
		
	
	_update_labels() # called to refresh the labels
	_refresh_audio_settings()
	
# Whenever a button is pressed, do:
func _on_button_pressed(button_name: String) -> void:
	current_button = $KeybindContainer.get_node(button_name)
	print(current_button)
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
		
func _on_audio_button_pressed(channel: String) -> void:
	var button = $AudioContainer.get_node("TouchScreenButton" + channel).get_node(channel + "Button")
	var bus_id = AudioServer.get_bus_index(channel)
	AudioServer.set_bus_mute(bus_id, button.text == "On")
	button.text = "On" if button.text == "Off" else "Off"
	
	if channel == "SFX": # let players hear sound for testing
		var soundPlayer = AudioStreamPlayer.new()
		soundPlayer.bus = &"SFX"
		soundPlayer.stream = bark_sound
		soundPlayer.finished.connect(soundPlayer.queue_free) 	# Auto-delete when finished
		add_child(soundPlayer)
		soundPlayer.play()
		
# refresh in case player plays again (see title screen again)
func _refresh_audio_settings():
	$AudioContainer/TouchScreenButtonMusic/MusicButton.text = "Off" if AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) else "On"
	$AudioContainer/TouchScreenButtonSFX/SFXButton.text = "Off" if AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")) else "On"
