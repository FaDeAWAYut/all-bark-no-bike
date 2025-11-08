extends Node
class_name ScreenEffects

@onready var camera: Camera2D
@onready var flashOverlay: ColorRect
@onready var damageOverlay: ColorRect
@onready var chargeFlashOverlay: ColorRect  # NEW: Blue flash for charge bark

var shakeIntensity: float = 0.0
var shakeDuration: float = 0.0
var originalCameraPosition: Vector2
var tween: Tween

func setup(targetCamera: Camera2D, screenSize: Vector2, parentNode: Node):
	camera = targetCamera
	originalCameraPosition = camera.position
	
	# Create flash overlay
	var canvasLayer = CanvasLayer.new()
	canvasLayer.name = "EffectsCanvas"
	
	flashOverlay = ColorRect.new()
	flashOverlay.color = Color.WHITE
	flashOverlay.modulate.a = 0.0
	flashOverlay.size = screenSize * 2
	flashOverlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	damageOverlay = ColorRect.new()
	damageOverlay.color = Color.RED
	damageOverlay.modulate.a = 0.0
	damageOverlay.size = screenSize * 2
	damageOverlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# NEW: Create blue flash overlay for charge bark
	chargeFlashOverlay = ColorRect.new()
	chargeFlashOverlay.color = Color.CYAN  # Bright blue color
	chargeFlashOverlay.modulate.a = 0.0
	chargeFlashOverlay.size = screenSize * 2
	chargeFlashOverlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	canvasLayer.add_child(flashOverlay)
	canvasLayer.add_child(damageOverlay)
	canvasLayer.add_child(chargeFlashOverlay)  # NEW: Add blue flash overlay
	parentNode.add_child(canvasLayer)
	
	tween = create_tween()

func screen_shake(intensity: float, duration: float):
	shakeIntensity = intensity
	shakeDuration = duration

func _process(delta: float):
	update_screen_shake(delta)

func update_screen_shake(delta: float):
	if shakeDuration > 0 and camera:
		var shakeOffset = Vector2(
			randf_range(-shakeIntensity, shakeIntensity),
			randf_range(-shakeIntensity, shakeIntensity)
		)
		camera.position = originalCameraPosition + shakeOffset
		
		shakeDuration -= delta
		
		if shakeDuration > 0:
			var progress = 1.0 - (shakeDuration / (shakeDuration + delta))
			shakeIntensity = lerp(shakeIntensity, 0.0, progress)
		else:
			shakeIntensity = 0.0
	elif camera:
		camera.position = originalCameraPosition

func screen_flash(targetOpacity: float, duration: float):
	if flashOverlay and tween:
		tween.kill()
		tween = create_tween()
		tween.tween_property(flashOverlay, "modulate:a", targetOpacity, duration * 0.3)
		tween.tween_property(flashOverlay, "modulate:a", 0.0, duration * 0.7)
		
func screen_damage_flash(targetOpacity: float, duration: float):
	if damageOverlay and tween:
		tween.kill()
		tween = create_tween()
		tween.tween_property(damageOverlay, "modulate:a", targetOpacity, 0)
		tween.tween_property(damageOverlay, "modulate:a", 0.0, duration * 0.8)

func screen_charge_flash(targetOpacity: float = 0.6, duration: float = 0.2):
	if chargeFlashOverlay and tween:
		tween.kill()
		tween = create_tween()
		# Quick flash in and slower fade out
		tween.tween_property(chargeFlashOverlay, "modulate:a", targetOpacity, duration * 0.2)
		tween.tween_property(chargeFlashOverlay, "modulate:a", 0.0, duration * 0.8)
