extends PoolObject

class_name Collectable
signal coughdrop_collected

var is_collected: bool = false

func collect():
	if is_collected:
		return  # Prevent multiple collections
	
	is_collected = true
	
	# Immediate visual and collision disable
	var area_2d = get_node_or_null("Area2D")
	if area_2d:
		area_2d.monitoring = false
		area_2d.monitorable = false
	visible = false
	
	coughdrop_collected.emit() 
	return_to_pool()

func activate():
	super.activate()
	is_collected = false  # Reset flag
	# Re-enable everything
	var area_2d = get_node_or_null("Area2D")
	if area_2d:
		area_2d.monitoring = true
		area_2d.monitorable = true
	visible = true
