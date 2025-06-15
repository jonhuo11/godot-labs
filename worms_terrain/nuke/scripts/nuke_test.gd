extends Node2D

@export var NukeScene: PackedScene

var nukes: Array = []
var dead_nukes: Array = []

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var nuke = NukeScene.instantiate()
		nuke.position = get_global_mouse_position()
		
		add_child(nuke)
		nukes.append(nuke)
