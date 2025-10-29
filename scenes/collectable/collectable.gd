extends PoolObject

class_name Collectable
signal item_collected

func collect():
	item_collected.emit() 
	return_to_pool()
