class_name BossState extends State

const DRIVING = "Driving"
const TURNING = "Turning"
const THROWING = "Throwing"
const HURTING = "Hurting"
const STUNNED = "Stunned"

var boss: Motorbike

func _ready() -> void:
	await owner.ready
	boss = owner as Motorbike
	assert(boss != null, "The BossState state type must be used only in the boss scene. It needs the owner to be a Motorbike node.")
