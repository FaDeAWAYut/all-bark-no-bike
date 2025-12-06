extends Collectable

var collectable_type: String = "chadchart"

func _ready() -> void: 
	$CollisionShape2D.set_deferred("disabled", false)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		super.collect()

func _process(_delta: float) -> void:
	var old_position: Vector2 = position
	position = Vector2(old_position.x - 1, old_position.y + 1)
