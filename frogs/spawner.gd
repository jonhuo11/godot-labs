extends Node2D

@export var mob_scene: PackedScene

func _on_button_pressed() -> void:
	var mob = mob_scene.instantiate()
	mob.position = position
	add_child(mob)
