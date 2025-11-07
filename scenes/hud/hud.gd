extends CanvasLayer

@onready var healthBar = $TextureProgressBar
@onready var heart = $Sprite2D
@onready var timer = $Panel

@export var floatAmplitude: float = 2
@export var floatFrequency: float = 0.4
@export var floatEnabled: bool = true

var healthBarOriginalPosition: Vector2
var heartOriginalPosition: Vector2
var timerOriginalPosition: Vector2
var time: float = 0.0

func _ready():
	healthBarOriginalPosition = healthBar.position
	heartOriginalPosition = heart.position
	timerOriginalPosition = timer.position

func _process(delta):
	if not floatEnabled:
		return
		
	time += delta
	
	#floating effect
	var healthBarFloatOffset = sin(time * floatFrequency * TAU) * floatAmplitude
	healthBar.position.y = healthBarOriginalPosition.y + healthBarFloatOffset
	
	var heartFloatOffset = sin(time * floatFrequency * TAU - 1) * floatAmplitude
	heart.position.y = heartOriginalPosition.y + heartFloatOffset
	
	#var timerFloatOffset = sin(time * floatFrequency * TAU+ 1) * floatAmplitude
	#timer.position.y = timerOriginalPosition.y + timerFloatOffset
	
	
	
