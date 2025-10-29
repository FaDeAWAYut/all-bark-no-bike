extends Node
class_name ScreenEffects

@onready var camera: Camera2D
@onready var flashOverlay: ColorRect

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
	
	canvasLayer.add_child(flashOverlay)
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
		shakeIntensity = lerp(shakeIntensity, 0.0, 1.0 - (shakeDuration / 0.1))
	elif camera:
		camera.position = originalCameraPosition

func screen_flash(targetOpacity: float, duration: float):
	if flashOverlay and tween:
		tween.kill()
		tween = create_tween()
		tween.tween_property(flashOverlay, "modulate:a", targetOpacity, duration * 0.3)
		tween.tween_property(flashOverlay, "modulate:a", 0.0, duration * 0.7)
