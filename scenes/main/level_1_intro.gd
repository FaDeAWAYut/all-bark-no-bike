extends Node


func _ready():
	AudioServer.set_bus_volume_db(2, 0.0) # set SFX volume
	print("intro SFX: ",AudioServer.get_bus_volume_db(2))
