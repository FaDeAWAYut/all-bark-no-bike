extends CanvasLayer

@onready var isPhaseOne = get_parent().name == "Phase1"

@onready var healthBar = $TextureProgressBar
@onready var chargeBar = $TextureProgressBarCharge
@onready var heart = $Sprite2D
@onready var bluefire = $Sprite2DCharge
@onready var timer = $Timer
@onready var shield = $TextureRect
@onready var bosshealth = $TextureProgressBarBoss

@export var floatAmplitude: float = 2
@export var floatFrequency: float = 0.4
@export var floatEnabled: bool = true

@onready var timerPositionPhaseOne: Vector2 = Vector2(50, 94)
@onready var timerPositionPhaseTwo: Vector2 = Vector2(368, 15)

var healthBarOriginalPosition: Vector2
var heartOriginalPosition: Vector2
var chargeOriginalPosition: Vector2
var bluefireOriginalPosition: Vector2
var timerOriginalPosition: Vector2
var shieldOriginalPosition: Vector2
var bossOriginalPosition: Vector2
var time: float = 0.0

func _ready():
	healthBarOriginalPosition = healthBar.position
	heartOriginalPosition = heart.position
	chargeOriginalPosition = chargeBar.position
	bluefireOriginalPosition = bluefire.position
	shieldOriginalPosition = shield.position
	bossOriginalPosition = bosshealth.position
	
	timer.global_position = timerPositionPhaseOne if isPhaseOne else timerPositionPhaseTwo
	timer.scale = Vector2(1.0, 1.0) if isPhaseOne else Vector2(1.5, 1.5)
	bosshealth.visible = isPhaseOne 

func _process(delta):
	if not floatEnabled:
		return
		
	time += delta
	
	#floating effect
	var healthBarFloatOffset = sin(time * floatFrequency * TAU) * floatAmplitude
	healthBar.position.y = healthBarOriginalPosition.y + healthBarFloatOffset
	chargeBar.position.y = chargeOriginalPosition.y + healthBarFloatOffset
	shield.position.y = shieldOriginalPosition.y + healthBarFloatOffset
	bosshealth.position.y = bossOriginalPosition.y + healthBarFloatOffset
	#timer.position.y = timerOriginalPosition.y + healthBarFloatOffset
	#idontlikethetimer floating lmfao
	
	var heartFloatOffset = sin(time * floatFrequency * TAU - 1) * floatAmplitude
	heart.position.y = heartOriginalPosition.y + heartFloatOffset
	bluefire.position.y = bluefireOriginalPosition.y + heartFloatOffset
	
	#var timerFloatOffset = sin(time * floatFrequency * TAU+ 1) * floatAmplitude
	#timer.position.y = timerOriginalPosition.y + timerFloatOffset
	
	
	
