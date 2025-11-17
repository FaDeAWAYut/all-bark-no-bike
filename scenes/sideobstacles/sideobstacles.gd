extends PoolObject

class_name SidewalkObstacle

var currentSpeed: float = 0.0

func _ready():
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")
	
func _process(delta):
	if is_active:
		position.y += currentSpeed * delta * 2

func set_speed(speed: float):
	currentSpeed = speed

func activate():
	super.activate()
	currentSpeed = 0.0
	
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")
