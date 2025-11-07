extends CanvasLayer

@onready var healthBar = $TextureProgressBar
@onready var chargeBar = $TextureProgressBarCharge
@onready var heart = $Sprite2D
@onready var bluefire = $Sprite2DCharge
@onready var timer = $Panel

@export var floatAmplitude: float = 2
@export var floatFrequency: float = 0.4
@export var floatEnabled: bool = true

var healthBarOriginalPosition: Vector2
var heartOriginalPosition: Vector2
var chargeOriginalPosition: Vector2
var bluefireOriginalPosition: Vector2
var timerOriginalPosition: Vector2
var time: float = 0.0

func _ready():
	healthBarOriginalPosition = healthBar.position
	heartOriginalPosition = heart.position
	chargeOriginalPosition = chargeBar.position
	bluefireOriginalPosition = bluefire.position
	timerOriginalPosition = timer.position

func _process(delta):
	if not floatEnabled:
		return
		
	time += delta
	
	#floating effect
	var healthBarFloatOffset = sin(time * floatFrequency * TAU) * floatAmplitude
	healthBar.position.y = healthBarOriginalPosition.y + healthBarFloatOffset
	chargeBar.position.y = chargeOriginalPosition.y + healthBarFloatOffset
	#timer.position.y = timerOriginalPosition.y + healthBarFloatOffset
	#idontlikethetimer floating lmfao
	
	var heartFloatOffset = sin(time * floatFrequency * TAU - 1) * floatAmplitude
	heart.position.y = heartOriginalPosition.y + heartFloatOffset
	bluefire.position.y = bluefireOriginalPosition.y + heartFloatOffset
	
	#var timerFloatOffset = sin(time * floatFrequency * TAU+ 1) * floatAmplitude
	#timer.position.y = timerOriginalPosition.y + timerFloatOffset
	
	
	
