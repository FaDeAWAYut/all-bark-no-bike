extends PoolObject

# Car-specific properties
var currentSpeed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_active:
		# Move downward at current speed
		position.y += currentSpeed * delta

func set_speed(speed: float):
	currentSpeed = speed

# Override activate to reset position and properties
func activate():
	super.activate()
	currentSpeed = 0.0
