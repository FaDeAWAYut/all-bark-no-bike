extends Control

@onready var panel = $Panel
@onready var label = $Panel/Label
@onready var hide_timer = $Timer

@export var show_duration: float = 5.0  # How long to show before auto-hiding
@export var fade_duration: float = 0.2  # Fade in/out duration

@onready var useTouchscreen = DisplayServer.is_touchscreen_available()

func _ready():
	# Start hidden
	modulate.a = 0.0
	visible = false
	
	# Connect timer
	if hide_timer:
		hide_timer.timeout.connect(_on_hide_timer_timeout)

# Show the objective with text (always waits 2 seconds)
func show_objective(text: String, auto_hide: bool = true):
	# Wait 2 seconds before showing
	await get_tree().create_timer(1.5).timeout
	
	label.text = text
	visible = true
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	
	# Start auto-hide timer if enabled
	if auto_hide and hide_timer:
		hide_timer.start(show_duration)

# Show immediately without delay (if needed)
func show_objective_immediately(text: String, auto_hide: bool = true):
	label.text = text
	visible = true
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	
	# Start auto-hide timer if enabled
	if auto_hide and hide_timer:
		hide_timer.start(show_duration)

# Hide the objective
func hide_objective():
	if hide_timer:
		hide_timer.stop()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(func(): visible = false)

func _on_hide_timer_timeout():
	hide_objective()

# Manual control functions
func set_objective_text(text: String):
	label.text = text

func is_panel_visible() -> bool:
	return visible and modulate.a > 0
