extends Node

class_name Collectable
signal item_collected

func collect():
	item_collected.emit() 
	queue_free()
