class_name Nuke

extends RigidBody2D

@export var max_thrust_force = 10

@export var Explosion: PackedScene

@onready var explosion_area_collider_poly := $CollisionPolygon2D
@onready var sprite = $Sprite2D
@onready var collider = $CollisionShape2D

signal explode(at: Vector2, hit_obj: Node2D, explosion_area: CollisionPolygon2D)

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	connect("body_entered", self._on_body_entered)


func _on_body_entered(other: Node) -> void:
	if other is Nuke:
		_explode(other)
	elif other is Node2D and other.owner is Node2D:
		_explode(other.owner)


func _explode(other: Node2D) -> void:
	emit_signal('explode', global_position, other, explosion_area_collider_poly)

	# disable the rocket
	call_deferred("_disable_myself")

	# spawn explosion
	var expl = Explosion.instantiate()
	expl.position = position
	add_sibling(expl)



func _disable_myself() -> void:
	Global.set_enabled_rbody(self, false)


func _physics_process(_delta: float) -> void:
	var thrust_force: Vector2 = _mouse_follow().limit_length(max_thrust_force)
	apply_central_force(thrust_force)
	
	rotation = (linear_velocity.angle() + deg_to_rad(90))


func _mouse_follow() -> Vector2:
	var dist = get_global_mouse_position() - global_position
	return (dist).normalized() * dist.length_squared()
