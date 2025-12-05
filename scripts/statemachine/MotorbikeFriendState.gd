class_name MotorbikeFriendState extends State

const DRIVING = "Driving"
const TURNING = "Turning"
const THROWING = "Throwing"
const ZOOMING = "Zooming"

var boss: MotorbikeFriend

func _ready() -> void:
	await owner.ready
	boss = owner as MotorbikeFriend
	assert(boss != null, "The MotorbikeFriendState state type must be used only in the motorbike_friend scene. It needs the owner to be a MotorbikeFriend node.")
