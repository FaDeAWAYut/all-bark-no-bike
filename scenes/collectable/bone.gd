extends Collectable

var collectable_type: String = "health"
		
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		super.collect()
