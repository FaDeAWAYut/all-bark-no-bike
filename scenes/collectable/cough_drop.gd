extends Collectable

func _on_area_2d_body_entered(body: Node2D) -> void:
	super.collect()
