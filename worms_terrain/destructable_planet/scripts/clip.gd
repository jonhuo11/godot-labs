
class_name DestructablePlanet

extends Node2D

@onready var collision_poly := $StaticBody2D/CollisionPolygon2D
@onready var sprite_poly := $Polygon2D

func _ready() -> void:
	clip_myself(CollisionPolygon2D.new())


func clip_myself(colliding_poly: CollisionPolygon2D) -> void:
	print("clipping ", self.name)

	var clipping_poly := colliding_poly.polygon
	var clipped_poly := Geometry2D.clip_polygons(
		_shift_vectors(sprite_poly.polygon, sprite_poly.global_position),
		_shift_vectors(clipping_poly, colliding_poly.global_position)
	)

	var final = _shift_vectors(clipped_poly[0], -global_position)
	final.reverse()
	sprite_poly.polygon = final # TODO: if nothing is left, handle it
	collision_poly.set_deferred("polygon", final)


func _shift_vectors(vec: PackedVector2Array, shift_by: Vector2) -> PackedVector2Array:
	var out = []
	for pt in vec:
		out.append(pt + shift_by)
	return out
