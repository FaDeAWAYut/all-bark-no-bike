extends Area2D

@onready var anim = $AnimatedSprite2D
@export var speed = 1200
@export var damage = 10

# New export variables for customization
@export var fadeInTime: float = 0.1
@export var squeezeScaleX: float = 0.1
@export var squeezeScaleY: float = 1.2
@export var scaleTransitionTime: float = 0.5

var direction = Vector2.UP
var tween: Tween

func _ready() -> void:
	# Initialize tween
	tween = create_tween()
	tween.set_parallel(true)  # Run animations in parallel
	
	# Start with zero opacity and squeezed scale
	anim.modulate.a = 0
	anim.scale = Vector2(squeezeScaleX, squeezeScaleY)
	
	# Play animation
	anim.play("chargebark")
	
	# Fade in opacity
	tween.tween_property(anim, "modulate:a", 1.0, fadeInTime)
	
	# Scale animation: from squeezed to normal with ease-in
	tween.tween_property(anim, "scale", Vector2(1.0, 1.0), scaleTransitionTime).set_ease(Tween.EASE_IN)
	
	# Connect the area_entered signal if not connected in the editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Auto-destruct after 3 seconds
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move upward
	global_position += direction * speed * delta
	
	# Remove if off-screen
	if global_position.y < -2000:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.name == "Motorbike" or body.is_in_group("enemy"):
		# Apply damage
		pass
		# Play hit effect
