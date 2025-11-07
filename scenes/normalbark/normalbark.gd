extends PoolObject

class_name NormalBark

@onready var anim = $AnimatedSprite2D/AnimatedSprite2D
@onready var area_2d: Area2D = $AnimatedSprite2D

# Group for basic properties
@export_group("Basic Properties")
@export var speed = 1200
@export var damage = 10

# Group for appearance customization
@export_group("Appearance Settings")
@export var fadeInTime: float = 0.1
@export var squeezeScaleX: float = 0.1
@export var squeezeScaleY: float = 1.2
@export var scaleTransitionTime: float = 0.5

var direction = Vector2.UP
var tween: Tween
var lifetime_timer: Timer

func _ready() -> void:
	# Create lifetime timer
	lifetime_timer = Timer.new()
	lifetime_timer.wait_time = 0.6
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(lifetime_timer)
	
	# Connect the area_entered signal if not connected in the editor
	if not area_2d.body_entered.is_connected(_on_body_entered):
		area_2d.body_entered.connect(_on_body_entered)
		
	# Start deactivated
	deactivate()

func activate():
	super.activate()
	
	# Reset properties
	direction = Vector2.UP
	
	# Enable collision detection
	if area_2d:
		area_2d.monitoring = true
		area_2d.monitorable = true
		area_2d.collision_layer = 1
		area_2d.collision_mask = 1
	
	# Initialize visual effects
	setup_visual_effects()
	
	# Start lifetime timer
	lifetime_timer.start()

func deactivate():
	super.deactivate()
	
	# Stop timer
	if lifetime_timer:
		lifetime_timer.stop()
	
	# Stop tween
	if tween:
		tween.kill()
	
	# DISABLE collision detection when deactivated
	if area_2d:
		area_2d.monitoring = false
		area_2d.monitorable = false
		area_2d.collision_layer = 0
		area_2d.collision_mask = 0

func setup_visual_effects():
	# Initialize tween
	tween = create_tween()
	tween.set_parallel(true)  # Run animations in parallel
	
	# Start with zero opacity and squeezed scale
	anim.modulate.a = 0
	anim.scale = Vector2(squeezeScaleX, squeezeScaleY)
	
	# Play animation
	anim.play("normal_bark")
	
	# Fade in opacity
	tween.tween_property(anim, "modulate:a", 1.0, fadeInTime)
	
	# Scale animation: from squeezed to normal with ease-in
	tween.tween_property(anim, "scale", Vector2(1.0, 1.0), scaleTransitionTime).set_ease(Tween.EASE_IN)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	# Move upward
	global_position += direction * speed * delta
	
	# Remove if off-screen
	if global_position.y < -50:
		return_to_pool()

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemy"):
		# Store the collision position
		var collision_position = global_position
		
		# Apply damage to the boss if it's the motorbike
		if body.has_method("take_damage"):
			print("take damage")
			body.take_damage(damage, collision_position)  # Pass the position
		elif body.BossHealthController and body.BossHealthController.has_method("take_damage"):
			body.BossHealthController.take_damage(damage, collision_position)  # Pass the position
		
		return_to_pool()

func _on_lifetime_timeout():
	return_to_pool()
