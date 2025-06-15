extends Node2D

@export var NukeScene: PackedScene



func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var nuke = NukeScene.instantiate()
		nuke.position = get_global_mouse_position()
		
		add_child(nuke)
		nuke.explode.connect(self._on_nuke_exploded)


func _on_nuke_exploded(_at: Vector2, hit_obj: Node2D, explosion_area: CollisionPolygon2D):
	if hit_obj is DestructablePlanet:
		hit_obj.clip_myself(explosion_area)